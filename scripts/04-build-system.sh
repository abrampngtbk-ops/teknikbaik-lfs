#!/bin/bash
set -e

#Run this when logged off and machine is off|
sudo su -

export LFS=/mnt/lfs

mount -v -t ext4 /dev/sda4 $LFS

mount -v --bind /dev $LFS/dev
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login

cd /sources
tar -xf man-pages-6.17.tar.xz
cd man-pages-6.17

rm -v man3/crypt*

make -R GIT=false prefix=/usr install

cd /sources
rm -rf man-pages-6.17

cd /sources
tar -xf iana-etc-20260202.tar.*
cd iana-etc-20260202

cp -v services protocols /etc

cd /sources
rm -rf iana-etc-20260202

cd /sources
tar -xf glibc-2.43.tar.xz
cd glibc-2.43

patch -Np1 -i ../glibc-fhs-1.patch

mkdir -v build
cd build

echo "rootsbindir=/usr/sbin" > configparms

../configure --prefix=/usr                   \
             --disable-werror                \
             --disable-nscd                  \
             libc_cv_slibdir=/usr/lib        \
             --enable-stack-protector=strong \
             --enable-kernel=5.4

make

touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install

sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

# --- INSTALASI SEMUA LOCALEDEF STANDAR LFS ---
localedef -i C -f UTF-8 C.UTF-8
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i id_ID -f UTF-8 id_ID.UTF-8      # <-- Tambahan khusus Indonesia
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8

# --- KONFIGURASI JARINGAN ---
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf
passwd: files systemd
group: files systemd
shadow: files systemd
hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
networks: files
protocols: files
services: files
ethers: files
rpc: files
# End /etc/nsswitch.conf
EOF

# --- KONFIGURASI ZONA WAKTU ---
tar -xf ../../tzdata2025c.tar.gz
ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO tz


ln -sfv /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# --- KONFIGURASI DYNAMIC LOADER ---
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib
EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf
EOF

mkdir -pv /etc/ld.so.conf.d

cd /sources
rm -rf glibc-2.43

cd /sources
tar -xf zlib-1.3.2.tar.*
cd zlib-1.3.2

./configure --prefix=/usr

make

make check

make install
rm -fv /usr/lib/libz.a

cd /sources
rm -rf zlib-1.3.2

cd /sources
tar -xf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8

patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch

sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

make -f Makefile-libbz2_so
make clean
make

make PREFIX=/usr install

cp -av libbz2.so.* /usr/lib
ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so
ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so.1

cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done

rm -fv /usr/lib/libbz2.a

cd /sources
rm -rf bzip2-1.0.8

cd /sources
tar -xf xz-5.8.2.tar.xz
cd xz-5.8.2

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.8.2

make

make check

make install

cd /sources
rm -rf xz-5.8.2

cd /sources
tar -xf lz4-1.10.0.tar.*
cd lz4-1.10.0

make BUILD_STATIC=no PREFIX=/usr

make -j1 check

make BUILD_STATIC=no PREFIX=/usr install

cd /sources
rm -rf lz4-1.10.0

cd /sources
tar -xf zstd-1.5.7.tar.*
cd zstd-1.5.7

make prefix=/usr

make check

make prefix=/usr install

rm -v /usr/lib/libzstd.a

cd /sources
rm -rf zstd-1.5.7

cd /sources
tar -xf file-5.46.tar.*
cd file-5.46

./configure --prefix=/usr

make

make check

make install

cd /sources
rm -rf file-5.46

cd /sources
tar -xf readline-8.3.tar.*
cd readline-8.3

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf

sed -e '270a\
     else\
       chars_avail = 1;'      \
    -e '288i\   result = -1;' \
    -i.orig input.c

./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.3

make SHLIB_LIBS="-lncursesw"

make install

# Menginstal dokumentasi opsional
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.3

cd /sources
rm -rf readline-8.3

cd /sources
tar -xf pcre2-10.47.tar.*
cd pcre2-10.47

./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/pcre2-10.47 \
            --enable-unicode                    \
            --enable-jit                        \
            --enable-pcre2-16                   \
            --enable-pcre2-32                   \
            --enable-pcre2grep-libz             \
            --enable-pcre2grep-libbz2           \
            --enable-pcre2test-libreadline      \
            --disable-static

make

make check

make install

cd /sources
rm -rf pcre2-10.47

cd /sources
tar -xf m4-1.4.21.tar.*
cd m4-1.4.21

./configure --prefix=/usr

make

make check

make install

cd /sources
rm -rf m4-1.4.21

cd /sources
tar -xf bc-7.0.3.tar.*
cd bc-7.0.3

CC='gcc -std=c99' ./configure --prefix=/usr -G -O3 -r

make

make test

make install

cd /sources
rm -rf bc-7.0.3

cd /sources
tar -xf flex-2.6.4.tar.*
cd flex-2.6.4

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/flex-2.6.4

make

make check

make install

# Membuat topeng 'lex' untuk backward compatibility
ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1

cd /sources
rm -rf flex-2.6.4

cd /sources
tar -xf tcl8.6.17-src.tar.gz
cd tcl8.6.17

SRCDIR=$(pwd)
cd unix

./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --disable-rpath

make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.12|/usr/lib/tdbc1.1.12|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.12/generic|/usr/include|"     \
    -e "s|$SRCDIR/pkgs/tdbc1.1.12/library|/usr/lib/tcl8.6|"  \
    -e "s|$SRCDIR/pkgs/tdbc1.1.12|/usr/include|"             \
    -i pkgs/tdbc1.1.12/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.4|/usr/lib/itcl4.3.4|" \
    -e "s|$SRCDIR/pkgs/itcl4.3.4/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.3.4|/usr/include|"            \
    -i pkgs/itcl4.3.4/itclConfig.sh

unset SRCDIR

LC_ALL=C.UTF-8 make test

make install

chmod 644 /usr/lib/libtclstub8.6.a
chmod -v u+w /usr/lib/libtcl8.6.so

make install-private-headers

ln -sfv tclsh8.6 /usr/bin/tclsh
mv -v /usr/share/man/man3/{Thread,Tcl_Thread}.3

# Instalasi dokumentasi opsional (direkomendasikan)
cd ..
tar -xf ../tcl8.6.17-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.17
cp -v -r  ./html/* /usr/share/doc/tcl-8.6.17

cd /sources
rm -rf tcl8.6.17

cd /sources
tar -xf expect5.45.4.tar.gz
cd expect5.45.4

# Menambal Expect agar kompatibel dengan GCC 15
patch -Np1 -i ../expect-5.45.4-gcc15-1.patch

./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include

make

make test

make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib

cd /sources
rm -rf expect5.45.4

cd /sources
tar -xf dejagnu-1.6.3.tar.*
cd dejagnu-1.6.3

mkdir -v build
cd build

../configure --prefix=/usr

makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi

make check

make install

# Menginstal dokumentasi
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

cd /sources
rm -rf dejagnu-1.6.3

cd /sources
tar -xf pkgconf-2.5.1.tar.*
cd pkgconf-2.5.1

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/pkgconf-2.5.1

make

make install

# Membuat topeng pkg-config untuk backward compatibility
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1

cd /sources
rm -rf pkgconf-2.5.1

cd /sources
tar -xf binutils-2.46.0.tar.*
cd binutils-2.46.0

mkdir -v build
cd build

../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --enable-new-dtags  \
             --with-system-zlib  \
             --enable-default-hash-style=gnu

make tooldir=/usr

# Menjalankan pengujian (Proses ini akan memakan waktu cukup lama!)
make -k check

# Mengecek daftar tes yang gagal
grep '^FAIL:' $(find -name '*.log')

make tooldir=/usr install

# Membersihkan file statis yang tidak berguna
rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
        /usr/share/doc/gprofng/

cd /sources
rm -rf binutils-2.46.0

cd /sources
tar -xf gmp-6.3.0.tar.*
cd gmp-6.3.0

# Menyesuaikan dengan GCC 15
sed -i '/long long t1;/,+1s/()/(...)/' configure

./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0

make
make html

# Menjalankan pengujian kritis dan menyimpan lognya
make check 2>&1 | tee gmp-check-log

# Menghitung jumlah tes yang berhasil (Target: minimal 199)
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log

make install
make install-html

cd /sources
rm -rf gmp-6.3.0

cd /sources
tar -xf mpfr-4.2.2.tar.*
cd mpfr-4.2.2

./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.2

make
make html

# Pengujian kritis (Perhatikan outputnya agar tidak ada yang FAIL)
make check

make install
make install-html

cd /sources
rm -rf mpfr-4.2.2

cd /sources
tar -xf mpc-1.3.1.tar.*
cd mpc-1.3.1

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1

make
make html

# Menjalankan pengujian (make check)
make check

make install
make install-html

cd /sources
rm -rf mpc-1.3.1

cd /sources
tar -xf attr-2.5.2.tar.*
cd attr-2.5.2

./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2

make

# Menjalankan pengujian (Pastikan berjalan sukses tanpa error)
make check

make install

cd /sources
rm -rf attr-2.5.2

cd /sources
tar -xf acl-2.3.2.tar.*
cd acl-2.3.2

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/acl-2.3.2

make

# Menjalankan pengujian (Abaikan FAIL pada test/cp.test!)
make check

make install

cd /sources
rm -rf acl-2.3.2

cd /sources
tar -xf libcap-2.77.tar.*
cd libcap-2.77

# Mencegah instalasi pustaka statis
sed -i '/install -m.*STA/d' libcap/Makefile

# Kompilasi dengan memaksa direktori ke /usr/lib
make prefix=/usr lib=lib

# Menjalankan pengujian
make test

# Instalasi final
make prefix=/usr lib=lib install

cd /sources
rm -rf libcap-2.77

cd /sources
tar -xf libxcrypt-4.5.2.tar.*
cd libxcrypt-4.5.2

# Memperbaiki kompatibilitas dengan Glibc terbaru
sed -i '/strchr/s/const//' lib/crypt-{sm3,gost}-yescrypt.c

./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens

make

# Menjalankan pengujian (Pastikan berjalan sukses)
make check

make install

cd /sources
rm -rf libxcrypt-4.5.2

# Menyalakan mode Shadow (menyembunyikan password)
pwconv
grpconv

# Mengatur grup bawaan untuk pembuatan pengguna baru
mkdir -p /etc/default
useradd -D --gid 999

passwd root

cd /sources
rm -rf shadow-4.19.3

cd /sources
tar -xf shadow-4.19.3.tar.*
cd shadow-4.19.3

# Membuang program 'groups' dan dokumentasi ganda
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

# Manipulasi kritis keamanan di login.defs
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs

# Memancing lokasi passwd yang benar
touch /usr/bin/passwd

./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --disable-logind    \
            --with-group-name-max-length=32

make

# Menginstal paket (tanpa pengujian)
make exec_prefix=/usr install
make -C man install-man

cd /sources
tar -xf gcc-15.2.0.tar.*
cd gcc-15.2.0

# 1. Penambalan wajib untuk Glibc 2.43
sed -i 's/char [*]q/const &/' libgomp/affinity-fmt.c

# 2. Penyesuaian arsitektur x86_64 agar menggunakan direktori /usr/lib murni
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

# 3. Membuat direktori build khusus
mkdir -v build
cd build

# 4. Konfigurasi GCC (Perhatikan semua parameternya sudah sesuai LFS)
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --enable-host-pie        \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib

# 5. Memulai kompilasi (Gunakan semua inti prosesormu untuk mempercepat!)
make -j$(nproc)

# 1. Menghapus batasan memori stack agar GCC tidak kehabisan nafas
ulimit -s -H unlimited

# 2. Menghapus satu tes yang dipastikan error bawaan (cpython)
sed -e '/cpython/d' -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp

# 3. Memberikan hak milik sementara kepada user tester
chown -R tester .

# 4. Menjalankan ribuan pengujian sebagai user non-root
su tester -c "PATH=$PATH make -j$(nproc) -k check"

# 5. Menampilkan rangkuman hasil pengujian
../contrib/test_summary | grep -A7 Summ

# 1. Instalasi GCC
make install

# 2. Mengembalikan hak milik header files kepada root
chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/15.2.0/include{,-fixed}

# 3. Membuat jalan pintas (symlink) yang diwajibkan oleh standar FHS Linux
ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/15.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

sudo su -

export LFS=/mnt/lfs

mount -v -t ext4 /dev/sda4 $LFS

mount -v --bind /dev $LFS/dev
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login

cd /sources
tar -xf sed-4.9.tar.*
cd sed-4.9

./configure --prefix=/usr

make
make html

chown -R tester .
su tester -c "PATH=$PATH make check"

make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9

cd /sources
rm -rf sed-4.9

cd /sources
tar -xf psmisc-23.7.tar.*
cd psmisc-23.7

./configure --prefix=/usr

make

make check

make install

cd /sources
rm -rf psmisc-23.7


cd /sources
tar -xf gettext-1.0.tar.*
cd gettext-1.0

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-1.0

make

make check

make install
chmod -v 0755 /usr/lib/preloadable_libintl.so

cd /sources
rm -rf gettext-1.0

cd /sources
tar -xf bison-3.8.2.tar.*
cd bison-3.8.2

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2

make

make check

make install

cd /sources
rm -rf bison-3.8.2

cd /sources
tar -xf grep-3.12.tar.*
cd grep-3.12

sed -i "s/echo/#echo/" src/egrep.sh

./configure --prefix=/usr

make

make check

make install

cd /sources
rm -rf grep-3.12

cd /sources
tar -xf bash-5.3.tar.*
cd bash-5.3

./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-5.3

make

chown -R tester .
LC_ALL=C.UTF-8 su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF

make install

cd /sources
rm -rf bash-5.3

exec /usr/bin/bash --login

cd /sources
tar -xf libtool-2.5.4.tar.*
cd libtool-2.5.4

./configure --prefix=/usr

make

make check

make install

rm -fv /usr/lib/libltdl.a

cd /sources
rm -rf libtool-2.5.4

cd /sources
tar -xf gdbm-1.26.tar.*
cd gdbm-1.26

./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat

make

make check

make install

cd /sources
rm -rf gdbm-1.26

cd /sources
tar -xf gperf-3.3.tar.*
cd gperf-3.3

./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.3

make

make check

make install

cd /sources
rm -rf gperf-3.3

cd /sources
tar -xf expat-2.7.4.tar.*
cd expat-2.7.4

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.7.4

make

make check

make install
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.7.4

cd /sources
rm -rf expat-2.7.4

cd /sources
tar -xf inetutils-2.7.tar.*
cd inetutils-2.7

sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c

./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers

make

make check

make install

mv -v /usr/bin/ifconfig /usr/sbin/ifconfig

cd /sources
rm -rf inetutils-2.7

cd /sources
tar -xf less-692.tar.*
cd less-692

./configure --prefix=/usr --sysconfdir=/etc

make

make check

make install

cd /sources
rm -rf less-692

cd /sources
tar -xf perl-5.42.0.tar.*
cd perl-5.42.0

export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des                                          \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                          \
             -D privlib=/usr/lib/perl5/5.42/core_perl      \
             -D archlib=/usr/lib/perl5/5.42/core_perl      \
             -D sitelib=/usr/lib/perl5/5.42/site_perl      \
             -D sitearch=/usr/lib/perl5/5.42/site_perl     \
             -D vendorlib=/usr/lib/perl5/5.42/vendor_perl  \
             -D vendorarch=/usr/lib/perl5/5.42/vendor_perl \
             -D man1dir=/usr/share/man/man1                \
             -D man3dir=/usr/share/man/man3                \
             -D pager="/usr/bin/less -isR"                 \
             -D useshrplib                                 \
             -D usethreads

make

TEST_JOBS=$(nproc) make test_harness

make install

unset BUILD_ZLIB BUILD_BZIP2

cd /sources
rm -rf perl-5.42.0

cd /sources
tar -xf XML-Parser-2.47.tar.*
cd XML-Parser-2.47

perl Makefile.PL

make

make test

make install

cd /sources
rm -rf XML-Parser-2.47

cd /sources
tar -xf intltool-0.51.0.tar.*
cd intltool-0.51.0

sed -i 's:\\\${:\\\$\\{:' intltool-update.in

./configure --prefix=/usr

make

make check

make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

cd /sources
rm -rf intltool-0.51.0

cd /sources
tar -xf autoconf-2.72.tar.*
cd autoconf-2.72

./configure --prefix=/usr

make

make check

make install

cd /sources
rm -rf autoconf-2.72

cd /sources
tar -xf automake-1.18.1.tar.*
cd automake-1.18.1

./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.18.1

make

make -j$(($(nproc)>4?$(nproc):4)) check

make install

cd /sources
rm -rf automake-1.18.1

# Please refer to lfs book because this script is not complete for all package