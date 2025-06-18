#!/bin/bash

CONFIG_DIR="/tmp/mirror-configs"
LOG_DIR="/tmp/mirror-logs"
MIRROR_LIST_URL="https://raw.githubusercontent.com/soranewa/mirrortool/refs/heads/main/list.txt"

mkdir -p "$CONFIG_DIR" "$LOG_DIR"

function fetch_mirror_list() {
  curl -s "$MIRROR_LIST_URL" | grep -E '^[^#].+' || echo "❌ Gagal memuat daftar mirror."
}

function list_www_folders() {
  i=1
  for dir in /var/www/*; do
    [[ -d "$dir" ]] || continue
    fname=$(basename "$dir")
    echo "$i) $fname"
    TARGETS[$i]="$dir"
    ((i++))
  done
}

function menu_main() {
  clear
  echo "======================================"
  echo "🪞 MENU MIRROR LINUX ISO"
  echo "======================================"
  echo "1. Pilih Mirror & Folder"
  echo "2. Start/Stop Mirroring"
  echo "3. Cek Status Mirroring"
  echo "0. Keluar"
  echo "======================================"
  read -rp "Pilih opsi [0-3]: " PILIH
  case $PILIH in
    1) setup_mirror ;;
    2) control_mirroring ;;
    3) check_all_status ;;
    0) exit 0 ;;
    *) echo "❌ Pilihan tidak valid"; sleep 1; menu_main ;;
  esac
}

function setup_mirror() {
  clear
  echo "📀 Daftar Mirror (dari $MIRROR_LIST_URL):"
  mapfile -t RAWS < <(fetch_mirror_list)
  if [[ ${#RAWS[@]} -eq 0 ]]; then echo "❌ Mirror kosong."; sleep 2; return; fi

  for i in "${!RAWS[@]}"; do
    NAME=$(echo "${RAWS[$i]}" | cut -d'|' -f1)
    URL=$(echo "${RAWS[$i]}" | cut -d'|' -f2)
    echo "$((i+1))) $NAME"
    MIRROR_NAMES[$i]="$NAME"
    MIRROR_URLS[$i]="$URL"
  done
  echo "0) Kembali"
  read -rp "Pilih nomor mirror: " MNUM
  [[ "$MNUM" == "0" ]] && return
  SELECTED_NAME="${MIRROR_NAMES[$((MNUM-1))]}"
  SELECTED_URL="${MIRROR_URLS[$((MNUM-1))]}"

  echo "\n📁 Pilih folder tujuan di /var/www:"
  unset TARGETS
  list_www_folders
  echo "0) Kembali"
  read -rp "Pilih nomor folder: " DNUM
  [[ "$DNUM" == "0" ]] && return
  DEST="${TARGETS[$DNUM]}"
  [[ -z "$DEST" ]] && echo "❌ Folder tidak valid" && sleep 1 && return

  NAME=$(basename "$DEST")
  echo "$SELECTED_NAME|$SELECTED_URL" > "$CONFIG_DIR/$NAME.url"

  SIZE=$(rsync --dry-run --stats "$SELECTED_URL" | grep "Total file size" | awk '{print $NF}' | tr -d ',')
  echo "$SIZE" > "$CONFIG_DIR/$NAME.size"

  echo "✅ Mirror \"$SELECTED_NAME\" diset untuk folder $NAME"
  sleep 2
}

function control_mirroring() {
  clear
  echo "🚀 Start/Stop Mirroring"
  CONFIGS=("$CONFIG_DIR"/*.url)
  [[ ${#CONFIGS[@]} -eq 0 ]] && echo "❌ Belum ada konfigurasi mirror." && sleep 2 && return

  for i in "${!CONFIGS[@]}"; do
    NAME=$(basename "${CONFIGS[$i]%.url}")
    META=$(cut -d'|' -f1 "${CONFIGS[$i]}")
    PIDFILE="$CONFIG_DIR/$NAME.pid"
    if [[ -f "$PIDFILE" ]] && ps -p $(cat "$PIDFILE") > /dev/null; then
      STATUS="🟢 ON"
    else
      STATUS="🔴 OFF"
    fi
    echo "$((i+1))) $NAME → $META [$STATUS]"
  done
  echo "0) Kembali"
  read -rp "Pilih folder untuk start/stop: " CHOICE
  [[ "$CHOICE" == "0" ]] && return

  NAME=$(basename "${CONFIGS[$((CHOICE-1))]%.url}")
  DEST="/var/www/$NAME"
  SOURCE=$(cut -d'|' -f2 "${CONFIGS[$((CHOICE-1))]}")
  LOGFILE="$LOG_DIR/${NAME}.log"
  PIDFILE="$CONFIG_DIR/${NAME}.pid"

  if [[ -f "$PIDFILE" ]] && ps -p $(cat "$PIDFILE") > /dev/null; then
    kill $(cat "$PIDFILE") && echo "🛑 Mirroring dihentikan untuk $NAME"
    rm -f "$PIDFILE"
  else
    rsync -a --progress "$SOURCE" "$DEST" > "$LOGFILE" 2>&1 &
    echo $! > "$PIDFILE"
    echo "✅ Mirroring dimulai untuk $NAME (PID: $!)"
  fi
  sleep 2
}

function check_all_status() {
  clear
  echo "📊 Status Semua Mirroring Aktif:"
  CONFIGS=("$CONFIG_DIR"/*.url)
  for CONFIG in "${CONFIGS[@]}"; do
    NAME=$(basename "$CONFIG" .url)
    LOG="$LOG_DIR/$NAME.log"
    PIDFILE="$CONFIG_DIR/$NAME.pid"
    SIZEFILE="$CONFIG_DIR/$NAME.size"
    SOURCE=$(cut -d'|' -f2 "$CONFIG")
    if [[ -f "$PIDFILE" ]] && ps -p $(cat "$PIDFILE") > /dev/null; then
      STATUS="🟢 ON"
      PID=$(cat "$PIDFILE")
      echo "🔄 $NAME (PID: $PID) [$STATUS]"
      FILE=$(tac "$LOG" | grep -m1 -oP '^\S+\.iso')
      PROGRESS_LINE=$(tac "$LOG" | grep -m1 -P '^[0-9,]+\s+[0-9]+%')
      PROGRESS=$(echo "$PROGRESS_LINE" | awk '{print $2}')
      [[ -z "$PROGRESS" ]] && PROGRESS="Selesai atau idle"
      echo "📦 File: $FILE"
      echo "📈 Progress: $PROGRESS"
      if [[ -f "$SIZEFILE" ]]; then
        TOTAL=$(cat "$SIZEFILE")
        TRANSFERRED=$(grep -Eo '^[0-9,]+\s+100%' "$LOG" | awk '{gsub(",", "", $1); sum+=$1} END{print sum}')
        PERCENT_TOTAL=$(( 100 * TRANSFERRED / TOTAL ))
        echo "📊 Total Progress: $PERCENT_TOTAL% ($((TRANSFERRED/1024/1024)) MB dari $((TOTAL/1024/1024)) MB)"
      fi
    else
      STATUS="🔴 OFF"
      echo "✅ $NAME [$STATUS] tidak aktif."
    fi
    echo "--------------------------------------"
  done
  echo "0) Kembali"
  read -rp "Tekan 0 untuk kembali: " _
}

while true; do
  menu_main
done
