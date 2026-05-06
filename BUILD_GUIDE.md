# Build Guide - Teknik Baik OS

## System Requirements
* **Host OS:** Ubuntu 25.10 
* **RAM:** 6GB minimum, 8GB+ recommended
* **Disk:** 65GB free space
* **CPU:** 2 cores minimum, 4 cores recommended

## Preparation Steps (LFS Chapter 2-4)
1. Host system setup
2. Partition preparation
3. Download sources with wget

## Build Process

### Phase 1 (LFS Chapter 5-6): Toolchain & Temporary Tools
Fase ini dilakukan di lingkungan *Host* (Ubuntu) dengan *user* `lfs` untuk membangun *compiler* silang (*cross-compiler*) dan alat-alat dasar sementara. 

**Catatan Implementasi:**
Seluruh langkah kompilasi pada fase ini merujuk pada pedoman resmi *Linux From Scratch Book*. Untuk efisiensi, dokumentasi *command lengkap*, dan kemudahan reproduksi sistem, kami telah merangkum seluruh perintah Phase 1 ke dalam skrip otomatisasi.
* **Lihat Script:** `scripts/02-build-toolchain.sh`

### Phase 2 (LFS Chapter 7-11): System Base 
Fase ini adalah membangun sistem operasi murni dari dalam lingkungan isolasi (Chroot). Sama halnya dengan Phase 1, perintah kompilasi untuk *Essential Packages* (seperti Coreutils, Bash, dll) kami rangkum dalam skrip otomatisasi.
* **Lihat Script:** `scripts/03-build-system.sh`

**Khusus Kompilasi Kernel:**
Kami melakukan penyesuaian (*tuning*) konfigurasi kernel agar OS ini optimal sebagai *Web Server*.
*   **Command:** `make menuconfig` lalu `make && make modules_install`
*   **Optimasi:** Mengaktifkan dukungan jaringan (Networking), File System (Ext4), dan driver SATA/AHCI menjadi *Built-in* (`[*]`), bukan Modul (`[M]`), agar *server* dapat *booting* mandiri tanpa *initramfs*.

### Phase 3 (BLFS): Theme-Specific (Server OS)
Fase ini adalah implementasi sistem operasi khusus untuk menjalankan *production web server*. Berikut adalah perintah spesifik yang kami eksekusi di dalam LFS:

**1. Nginx (Web Server) - Compiled from Source**
Kompilasi Nginx dari *source code* untuk menjalankan antarmuka web POS.
```bash
wget [http://nginx.org/download/nginx-1.24.0.tar.gz](http://nginx.org/download/nginx-1.30.0.tar.gz)
tar -xvf nginx-1.30.0.tar.gz
cd nginx-1.30.0
./configure --prefix=/usr --user=nginx --group=nginx --with-http_ssl_module
make
make install
```

**2. PHP-FPM - Compiled from Source**
Mengkompilasi PHP.
```bash
wget [https://www.php.net/distributions/php-8.2.10.tar.gz](https://www.php.net/distributions/php-8.5.3.tar.gz)
tar -xvf php-8.5.3.tar.gz
cd php-8.5.3
./configure --prefix=/usr                \
            --sysconfdir=/etc            \
            --localstatedir=/var         \
            --datadir=/usr/share/php     \
            --mandir=/usr/share/man      \
            --enable-fpm                 \
            --without-pear               \
            --with-fpm-user=apache       \
            --with-fpm-group=apache      \
            --with-fpm-systemd           \
            --with-config-file-path=/etc \
            --with-zlib                  \
            --enable-bcmath              \
            --with-bz2                   \
            --enable-calendar            \
            --enable-dba=shared          \
            --with-gdbm                  \
            --with-gmp                   \
            --enable-ftp                 \
            --with-gettext               \
            --enable-mbstring            \
            --disable-mbregex            \
            --with-readline              &&
make
make install                                     &&
install -v -m644 php.ini-production /etc/php.ini &&

install -v -m755 -d /usr/share/doc/php-8.5.3 &&
install -v -m644    CODING_STANDARDS* EXTENSIONS NEWS README* UPGRADING* \
                    /usr/share/doc/php-8.5.3

if [ -f /etc/php-fpm.conf.default ]; then
  mv -v /etc/php-fpm.conf{.default,} &&
  mv -v /etc/php-fpm.d/www.conf{.default,}
fi
```

**3. MariaDB (Database Server) v11.8.6 - Compiled from Source**
Menginstal MariaDB, serta mengonfigurasi *user/group* khusus demi keamanan *database*. Menggunakan `cmake` untuk proses kompilasinya.
```bash
# a. Membuat user dan group khusus database
groupadd -g 41 mysql
useradd -c "MySQL Server" -d /srv/mariadb -g mysql -s /bin/false -u 41 mysql

sed -i 's/regex system/regex/' \
       storage/columnstore/columnstore/cmake/boost.cmake

# b. Download dan Ekstrak
wget [https://downloads.mariadb.org/interstitial/mariadb-11.8.6/source/mariadb-11.8.6.tar.gz](https://downloads.mariadb.org/interstitial/mariadb-11.8.6/source/mariadb-11.8.6.tar.gz) -O mariadb-11.8.6.tar.gz
tar -xvf mariadb-11.8.6.tar.gz
cd mariadb-11.8.6

# c. Kompilasi menggunakan CMake
mkdir build &&
cd    build &&

cmake -D CMAKE_BUILD_TYPE=Release                       \
      -D CMAKE_INSTALL_PREFIX=/usr                      \
      -D GRN_LOG_PATH=/var/log/groonga.log              \
      -D INSTALL_DOCDIR=share/doc/mariadb-11.8.6        \
      -D INSTALL_DOCREADMEDIR=share/doc/mariadb-11.8.6  \
      -D INSTALL_MANDIR=share/man                       \
      -D INSTALL_MYSQLSHAREDIR=share/mariadb            \
      -D INSTALL_MYSQLTESTDIR=share/mariadb/test        \
      -D INSTALL_PAMDIR=lib/security                    \
      -D INSTALL_PAMDATADIR=/etc/security               \
      -D INSTALL_PLUGINDIR=lib/mariadb/plugin           \
      -D INSTALL_SBINDIR=sbin                           \
      -D INSTALL_SCRIPTDIR=bin                          \
      -D INSTALL_SQLBENCHDIR=share/mariadb/bench        \
      -D INSTALL_SUPPORTFILESDIR=share/mariadb          \
      -D MYSQL_DATADIR=/srv/mariadb                     \
      -D MYSQL_UNIX_ADDR=/run/mariadb/mariadb.sock      \
      -D WITH_EXTRA_CHARSETS=complex                    \
      -D WITH_EMBEDDED_SERVER=ON                        \
      -D SKIP_TESTS=ON                                  \
      -D TOKUDB_OK=0                                    \
      -W no-dev                                         \
      .. &&
make
make install
make install-mariadb

# 4. Post-Installation & Hak Akses
mkdir -p /srv/mariadb /etc/mysql
chown -R mysql:mysql /srv/mariadb
mariadb-install-db --user=mysql --basedir=/usr --datadir=/srv/mariadb
```

**4. CloudFlare**
Memasang Cloudflare Tunnel agar *server* lokal LFS dapat diakses secara publik dengan protokol HTTPS 
```bash
wget [https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64)
mv cloudflared-linux-amd64 /usr/bin/cloudflared
chmod +x /usr/bin/cloudflared

# Integrasi dengan Systemd
cloudflared service install <TOKEN_DARI_DASHBOARD_CLOUDFLARE>
systemctl start cloudflared
systemctl daemon-reload
```

**5. Systemd Services (Autopilot)**
Mendaftarkan seluruh servis "Tritunggal" (Nginx, PHP, MariaDB) beserta Cloudflare ke *Systemd* agar OS dapat beroperasi mandiri (*autopilot*) setiap kali komputer dihidupkan.
```bash
systemctl enable mariadb php-fpm nginx cloudflared
```

## Total Build Time
* **Estimated:** 24 +/- Hours with AMD Ryzen 7 7730U with Radeon Graphics

## Troubleshooting

### Common Errors dan Solusi

* **Error M4 (`#error "Assumed value of MB_LEN_MAX wrong"`):** 
  * **Penyebab:** Terjadi saat fase *make* paket `m4`. Ini disebabkan oleh bentrok header C (glibc) antara sistem *Host* (Ubuntu 25.10) dengan lingkungan sementara LFS, atau *source code* M4 membutuhkan *patch* spesifik untuk versi Glibc yang baru.
  * **Solusi:** Hapus folder ekstrak `m4` yang *error*, ekstrak ulang dari berkas `.tar`, lalu pastikan untuk menjalankan perintah *sed* (manipulasi teks) bawaan dari panduan buku LFS untuk memperbaiki *file* `lib/stdio.in.h` sebelum menjalankan `./configure`. Pastikan juga *environment variable* tidak bocor dari OS Host.

* **Error Chroot (`chroot: failed to run command '/usr/bin/env': No such file or directory`):**
  * **Penyebab:** Perintah gagal dijalankan saat mencoba masuk ke lingkungan *chroot* LFS. Sistem LFS tidak dapat menemukan program `env` di dalam `$LFS/usr/bin`. Ini biasanya terjadi karena pembuatan *symlink* direktori (seperti `/bin` ke `/usr/bin`) terlewat, atau kompilasi paket `coreutils` di fase *Temporary Tools* sebelumnya gagal/dilewati.
  * **Solusi:** Keluar dari *chroot*, periksa kembali direktori `$LFS/usr/bin`. Jika kosong, ulangi kompilasi paket `coreutils` pada fase *Cross Compiling Temporary Tools*, dan pastikan perintah pembuatan *symlink* awal dieksekusi dengan benar sebelum mencoba masuk *chroot* kembali.

* **Kernel Panic / Crash Saat Kompilasi (Out of Memory):** 
  * **Penyebab:** Terjadi *crash* atau *Kernel Panic* secara tiba-tiba di tengah proses kompilasi paket berat seperti **PHP** atau **GCC**. Penyebab utamanya adalah kehabisan memori RAM (Out of Memory). Alokasi RAM untuk VirtualBox berada di batas minimum (6GB), sementara di sistem operasi *Host* (Windows) terdapat terlalu banyak *tab browser* dan aplikasi tidak penting yang terbuka. Hal ini menyebabkan bentrokan *resource* RAM, sehingga Kernel LFS mati mendadak.
  * **Solusi:** Matikan paksa (Power Off) VirtualBox. Sebelum menyalakan dan mengulangi kompilasi, tutup semua *browser* dan aplikasi berat di *Host* Windows untuk membebaskan RAM. Selain itu, kurangi beban CPU dengan menurunkan jumlah *thread* pada parameter `make` (misalnya dari `make -j4` menjadi `make -j2`).

* **MariaDB User Error (`Unknown database 'db_pos'` / Gagal Start):** 
  * **Penyebab:** Layanan MariaDB gagal menyimpan atau membaca *database* karena *folder* penyimpanannya dikunci oleh `root`, atau *user* sistem `mysql` belum didaftarkan di dalam OS LFS.
  * **Solusi:** Buat grup dan pengguna khusus untuk database dengan perintah `groupadd -g 41 mysql` dan `useradd -c "MySQL Server" -d /srv/mariadb -g mysql -s /bin/false -u 40 mysql`. Setelah itu, inisialisasi ulang basis data dan ubah kepemilikan foldernya menggunakan perintah `chown -R mysql:mysql /srv/mariadb`.

* **Cloudflare Systemd Timeout (`Job for cloudflared.service failed because a timeout was exceeded`):** 
  * **Penyebab:** *Systemd* di LFS mencoba mematikan paksa `cloudflared` karena *service* tersebut diatur dengan `Type=notify`. Cloudflare gagal mengirimkan sinyal "active" kembali ke *Systemd*, sehingga dianggap *hang*.
  * **Solusi:** Edit file `/etc/systemd/system/cloudflared.service`. Ubah baris `Type=notify` menjadi `Type=simple`. Beritahu *Systemd* tentang perubahan ini dengan mengetik `systemctl daemon-reload`, lalu nyalakan ulang layanannya dengan `systemctl start cloudflared`.

### Verification Steps
* **Cek Kernel:** Jalankan perintah `uname -a` untuk memastikan sistem berjalan menggunakan Kernel LFS hasil kompilasi mandiri.
* **Cek Web Server:** Jalankan `systemctl status nginx` dan `systemctl status php-fpm`. Keduanya harus berstatus `active (running)`.
* **Cek Tunnel:** Akses URL *website* dari HP atau perangkat lain. Jika halaman *login* POS terbuka tanpa *error* 500, maka *database* dan *web server* sudah terintegrasi sempurna.