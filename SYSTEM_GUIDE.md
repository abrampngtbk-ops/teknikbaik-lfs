# System Documentation - TeknikBaik OS

## Arsitektur Sistem Overview
Sistem operasi TeknikBaik OS dibangun dari *source code* murni secara mandiri (berbasis Linux From Scratch). Arsitektur utamanya didesain tanpa *Graphical User Interface* untuk memaksimalkan stabilitas dan efisiensi *resource hardware*. Sistem ini difokuskan secara khusus untuk menjadi *Server OS* yang menjalankan aplikasi Point of Sales (POS). Manajemen servis dikendalikan oleh **Systemd**, memastikan seluruh kumpulan aplikasi web (Nginx, PHP, MariaDB, dan CloudFlare) berjalan secara *otomatis* ketika komputer dinyalakan.

## Package List 
Daftar lengkap *packages* beserta versinya dapat dilihat pada tautan berikut: 
[package-list.txt](packages/packages-list.txt)

## Kernel Configuration Choices
Kami menggunakan perintah `make defconfig` sebagai dasar (konfigurasi optimal bawaan arsitektur sistem), kemudian melakukan penyesuaian khusus:
* **Systemd Requirements:** Sesuai pedoman LFS, kami mengaktifkan fitur krusial agar Systemd dapat bekerja, seperti `CGROUPS` (untuk manajemen servis), `DEVTMPFS` (automount filesystem), dan `INOTIFY_USER`.
* **Server Optimization:** Kami mengatur *driver* File System (Ext4) dan SATA/AHCI menjadi *Built-in* (`[*]`) agar *server* dapat *booting* cepat tanpa *initramfs*.
* **Networking:** Mengaktifkan dukungan TCP/IP dan IPv6 secara penuh untuk keperluan *web server* dan *tunneling*.
* **Used Configuration** Daftar Konfigurasi yang kami gunakan dapat dilihat pada tautan berikut:
[configs/kernel.config](configs/kernel.config)

## File System Layout
Sistem operasi ini mengikuti standar Filesystem Hierarchy Standard (FHS):
* `/boot`: Menyimpan Linux Kernel dan file konfigurasi GRUB.
* `/etc`: Menyimpan file konfigurasi sistem dan aplikasi (seperti `/etc/nginx` dan `/etc/mysql`).
* `/srv`: Menyimpan data spesifik layanan (misal: `/srv/mariadb` untuk *database*, `/srv/www` untuk *file* web POS).
* `/usr`: Menyimpan mayoritas *binary executable* aplikasi dan *library*.
* `/var`: Menyimpan *log* sistem dan *spool files*.

## Init System Setup
* Menggunakan **Systemd**.
* Service yang di-enable (Otomatis berjalan saat *boot*): `nginx.service`, `php-fpm.service`, `mariadb.service`, `cloudflared.service`.

## Network Configuration
* **Local Network:** Menggunakan IP dinamis (DHCP) yang dikelola oleh `systemd-networkd`.
* **Public Access:** Tidak menggunakan *Port Forwarding* konvensional. Kami menggunakan **Cloudflare Zero Trust Tunnel** (`cloudflared`) untuk merutekan trafik lokal ke domain publik secara aman dengan enkripsi SSL/TLS.

## User & Permissions
Untuk menjaga keamanan, layanan tidak dijalankan menggunakan akses *root*:
* `root`: Superuser (Hanya untuk administrasi sistem inti).
* `nginx (40)`: Menjalankan *web server* Nginx dan PHP-FPM.
* `mariadb (41)`: *User* khusus tanpa akses *shell* (`/bin/false`) untuk menjalankan MariaDB secara terisolasi.

## Services Yang Running
* **Nginx** (Berjalan pada Port: `80` - TCP)
* **PHP-FPM** (Berjalan pada Port: `9000` - TCP)
* **MariaDB** (Berjalan pada Port: `3306` - TCP)
* **Cloudflared** (Koneksi *Outbound* ke *Edge Network* Cloudflare)

## Security Measures
TeknikBaik OS menerapkan prinsip *Defense in Depth* (Pertahanan Berlapis) untuk memastikan keamanan server, meliputi:

1. **Minimal Attack Surface:** Dibangun menggunakan metode *Linux From Scratch* (LFS), OS ini murni hanya berisi modul kernel dan *packages* yang esensial untuk operasional sistem POS. Tidak ada *bloatware* atau antarmuka grafis (GUI) yang dapat memperlebar celah kerentanan.
2. **Network & Transport Defense:** Mengimplementasikan aturan *firewall* otomatis (Iptables) dengan kebijakan *Default Policy: DROP* pada lalu lintas masuk (*inbound traffic*), dan hanya mengizinkan *port* esensial (22, 80, 443).
3. **Database Isolation:** MariaDB tidak membuka *port* jaringan (*Port 3306* ditutup), melainkan berkomunikasi secara eksklusif dengan web server melalui *Unix Socket* (`/run/mariadb/mariadb.sock`).
4. **Access Control & Privilege Escalation:** Akses *login* langsung menggunakan otorisasi `root` melalui SSH telah dinonaktifkan (`PermitRootLogin no`). Administrator wajib menggunakan otentikasi *user* biasa sebelum melakukan eskalasi *privilege* secara lokal.
5. **Information Security & Service Hardening:** Layanan Nginx dan PHP-FPM dijalankan oleh *user non-root* (`nginx`). *Server tokens* dan eksposur versi PHP di *HTTP Headers* telah dihilangkan. Selain itu, hak akses kepemilikan direktori web telah dibatasi dan *file debugging* telah dihapus untuk mencegah *Information Disclosure*.
6. **Zero Trust Tunneling & Credential Protection:** Menggunakan layanan Cloudflared untuk merutekan lalu lintas web melalui *tunnel* aman, mencegah penyerang mengetahui IP asli server. Token autentikasi diisolasi menggunakan *Environment Variables* agar tidak bocor pada pemantauan proses sistem.
7. **Active Defense (Mini-IPS):** Mengimplementasikan skrip *Intrusion Prevention System* kustom yang memantau *log* autentikasi. Sistem ini secara otomatis memblokir alamat IP penyerang pada level *firewall* jika terdeteksi melakukan serangan *brute-force* pada layanan SSH.
8. **Secure Remote Administration:** Mengimplementasikan jaringan privat virtual (WireGuard VPN) dengan membuat terowongan komunikasi terenkripsi pada antarmuka terisolasi (wg0), dan hanya mengizinkan akses masuk administratif (SSH) bagi klien yang memiliki Private Key kriptografi valid.

## Performance Benchmarks
Berikut adalah penggunaan *resource* saat *server* berjalan secara *idle*:
![Htop Benchmark](docs/screenshots/htop.png)

## Performance Profile & Architecture Comparation
Berbeda dengan distribusi Linux *mainstream* seperti Ubuntu atau Debian yang dirancang sebagai *General-Purpose OS* (mendukung berbagai macam perangkat keras dan skenario penggunaan), TeknikBaik OS dirancang dengan filosofi *Purpose-Built OS* (sistem operasi yang dibangun khusus untuk satu tujuan: menjalankan Web Server POS).

Pendekatan *Linux From Scratch* ini menghasilkan efisiensi metrik operasional berikut pada lingkungan pengujian kami:

* **Manajemen Penyimpanan (Disk Space):** Sistem secara keseluruhan beroperasi pada kapasitas penyimpanan sekitar **~8 GB**. Berbeda dengan *distro mainstream* yang ukurannya sering kali didominasi oleh aplikasi tambahan atau antarmuka grafis (GUI), alokasi 8 GB pada TeknikBaik OS difokuskan untuk tiga hal esensial: *Core OS* dan *Web Server Stack* fungsional (Nginx, MariaDB, PHP-FPM), lingkungan *toolchain* kompilator (*development tools*), serta preservasi *source code* Linux Kernel yang sengaja dipertahankan di dalam sistem untuk memfasilitasi penyesuaian modul atau *driver* secara cepat di masa mendatang.
* **Efisiensi Memori (RAM):** Pada kondisi *idle* dengan seluruh layanan esensial (Nginx, MariaDB, PHP-FPM, Cloudflared, dan SSH Daemon) berjalan aktif, sistem mencatat tingkat penggunaan RAM yang sangat rendah, yakni di kisaran **180 MB - 250 MB**. Efisiensi ini tercapai secara langsung berkat tidak ada layanan latar belakang (*background daemons*) yang umumnya termuat secara otomatis pada *distro* komersial.

---
### Diagrams
* **Boot Process Flowchart:** [docs/screenshots/boot-process-flowchart.jpeg](docs/screenshots/boot-process-flowchart.jpeg)
* **Package Dependency Graph:** [docs/screenshots/dependency-graph.jpeg](docs/screenshots/dependency-graph.jpeg)
* **System Architecture Diagram:** [docs/screenshots/system-architecture-diagram.jpeg](docs/screenshots/system-architecture-diagram.jpeg)