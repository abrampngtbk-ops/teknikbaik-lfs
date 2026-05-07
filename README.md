# 🚀 TeknikBaik OS (Linux From Scratch)

**Proyek UTS: Membangun Sistem Operasi Custom Berbasis Linux From Scratch (LFS)**
* **Mata Kuliah:** Sistem Operasi
* **Jurusan:** Teknik Informatika
* **Universitas:** Universitas Palangka Raya
* **Tahun Akademik:** 2026

## 👥 Tim Pengembang (Kelompok 1)
1. Abram Pangindoan Tambak - 2530205030005 - Peran: Build Master 
2. Cahya Evendy - 2530205030004 - Peran: Quality Control & Testing 
3. Haniel Pratama - 2530205030014 - Peran: Documentation Lead
4. Alva Rivales Matal - 2530105030027 - Peran: Diagram & Graph Maker
5. Andreas Akar - 2530205030006 - Peran: Diagram & Graph Maker

## 🎯 Tema Project
**Tema 1: Server OS (Web Server)**

Sistem operasi LFS ini dibangun dan dioptimalkan secara khusus untuk menjalankan lingkungan *web server* *production*. OS ini didesain *lightweight* tanpa *Graphical User Interface* (GUI), dan telah dikonfigurasi untuk menjalankan aplikasi POS (Point of Sales) secara otomatis ketika lfs sistem dinyalakan.

**Arsitektur Utama & Optimasi:**
* Minimal packages (No GUI).
* Web Server: **Nginx** 
* Runtime: **PHP-FPM**.
* Database: **MariaDB**.
* Networking & Security: **Cloudflared & Firewall** 
* Init Linux System: **Systemd 13.0 (259.1)** 

## 📂 Struktur Repository
Repository ini berisi seluruh dokumentasi, skrip, dan konfigurasi yang digunakan selama proses pembangunan LFS:

* 📄 `BUILD_GUIDE.md`: Panduan komprehensif langkah demi langkah proses *build* LFS dari nol.
* 📄 `SYSTEM_GUIDE.md`: Dokumentasi arsitektur sistem, daftar paket, dan konfigurasi *server*.
* 📁 `scripts/`: Berisi skrip bash yang merepresentasikan tahapan *build*.
* 📁 `configs/`: File konfigurasi penting (*kernel-config*, *fstab*, *network*).
* 📁 `packages/`: Daftar lengkap *package* beserta versinya.
* 📁 `docs/`: Diagram arsitektur dan dokumentasi *screenshot*.

## 🔗 Quick Links
* Demonstrasi Video Youtube: 
* Link Akses Web POS: https://pos-lfs-teknikbaik.ngd.my.id/

---
*Dibuat oleh Tim TeknikBaik.*
*"You don't truly understand something until you can build it from scratch."*