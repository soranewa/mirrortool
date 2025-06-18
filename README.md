# 🪞 Mirror Tool Repository

Script interaktif untuk membuat mirror lokal dari distribusi Linux (atau sumber lain via rsync), dengan fitur start/stop dan monitoring progres langsung dari terminal.

---

## 🚀 Fitur Utama

- ✅ Mengambil daftar mirror dari file `list.txt` (hosted di GitHub)
- ✅ Memilih folder tujuan dari `/var/www` (tampil otomatis)
- ✅ Menyimpan konfigurasi mirror per-folder
- ✅ Start dan Stop proses mirroring kapan saja (toggle)
- ✅ Menampilkan progres mirroring (file terakhir & persentase)
- ✅ Menjalankan `rsync` di background, aman & resume otomatis

---

## 📥 Cara Install

```bash
git clone https://github.com/soranewa/mirrortool.git
cd mirrortool
chmod +x mirrortool.sh
```

> Pastikan rsync sudah terinstal:
> ```bash
> sudo apt install rsync
> ```

---

## 🧑‍💻 Cara Menjalankan

```bash
./mirrortool.sh
```

Kamu akan melihat menu utama seperti ini:

```
🪞 MENU MIRROR REPOSITORY
======================================
1. Pilih Mirror & Folder
2. Start/Stop Mirroring
3. Cek Status Mirroring
0. Keluar
```

---

## 🧾 Format `list.txt`

Script membaca daftar mirror dari file teks yang ada di repo GitHub ini.

**Format:**
```
Nama Tampilan|URL rsync sumber
```

**Contoh:**
```
Ubuntu CD|rsync://mirror.unair.ac.id/ubuntu-cd/
Debian CD|rsync://mirror.unair.ac.id/debian-cd/
Linuxmint CD|rsync://mirror.unair.ac.id/linuxmint-cd/
Archlinux CD|rsync://mirror.unair.ac.id/archlinux/iso/
```

> Ganti URL `MIRROR_LIST_URL` di dalam script agar sesuai file milikmu:
> ```bash
> MIRROR_LIST_URL="https://raw.githubusercontent.com/username/mirrortool/main/list.txt"
> ```

---

## 📊 Status Mirroring

Contoh tampilan saat kamu cek status:

```
📊 Status Semua Mirroring Aktif:

🔄 mirror (PID: 14321) sedang berjalan...
📦 File: linuxmint-21.3-cinnamon-64bit.iso
📈 Progress: 63%
--------------------------------------
✅ ubuntu-cd selesai atau tidak aktif.
--------------------------------------
```

---

## 🗃️ Struktur File

- `/tmp/mirror-configs/*.url` → berisi nama + URL sumber mirror
- `/tmp/mirror-configs/*.pid` → menyimpan PID rsync yang sedang berjalan
- `/tmp/mirror-logs/*.log` → log mirroring dari rsync

---

## ⚠️ Catatan Penting

- File yang sudah terunduh tidak akan diulang (`rsync` akan melewati)
- Proses dapat dilanjutkan kapan saja
- Hanya 1 proses `rsync` per-folder yang aktif dalam 1 waktu

---

## 📄 Lisensi

MIT License — bebas digunakan, dimodifikasi, dan dibagikan.

---

## 🤝 Kontribusi

Pull request, saran, dan laporan bug sangat diterima 🙌
