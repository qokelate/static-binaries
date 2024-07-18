#!/bin/zsh

base="$PWD"

cd "$base"
git clone --recursive 'https://github.com/libimobiledevice/libimobiledevice.git'
git clone --recursive 'https://github.com/libimobiledevice/libimobiledevice-glue.git'
git clone --recursive 'https://github.com/openssl/openssl.git' --branch=OpenSSL_1_1_1-stable
git clone --recursive 'https://github.com/libimobiledevice/libusbmuxd.git'
git clone --recursive 'https://github.com/libimobiledevice/libplist.git'
git clone --recursive 'https://github.com/libimobiledevice/ideviceinstaller.git'
git clone --recursive 'https://github.com/nih-at/libzip.git'
git clone --recursive 'https://github.com/facebook/zstd.git'

set -ex

export CFLAGS="-I$base/libimobiledevice-glue/build/include"
export PKG_CONFIG_PATH="\
$base/zstd/build2/output/lib/pkgconfig:\
$base/libimobiledevice/build/lib/pkgconfig:\
$base/libzip/build/output/lib/pkgconfig:\
$base/libplist/build/lib/pkgconfig:\
$base/libusbmuxd/build/lib/pkgconfig:\
$base/openssl/build/lib/pkgconfig:\
$base/libimobiledevice-glue/build/lib/pkgconfig"

function build(){
	rm -rf "$PWD/build"
	
	git clean -fdx
	git reset --hard HEAD

	./autogen.sh --prefix="$PWD/build" --enable-static --disable-shared

	make -j4 'LDFLAGS=-all-static'

	make install
}

# build openssl
cd "$base/openssl"
rm -rf "$PWD/build"
[ `uname -m` = "arm64" ] && \
./Configure darwin64-arm64-cc \
    no-tests no-shared \
    "--prefix=$PWD/build"

[ `uname -m` = "x86_64" ] && \
./Configure darwin64-x86_64-cc \
    no-tests no-shared \
    "--prefix=$PWD/build"

make -j4 'LDFLAGS=-all-static'
make install_sw

# build libplist
cd "$base/libplist"
rm -rf "$PWD/build"
./autogen.sh --prefix="$PWD/build" --enable-static --disable-shared --without-cython
make -j4
make install

# build libimobiledevice-glue
cd "$base/libimobiledevice-glue"
build

# build libusbmuxd
cd "$base/libusbmuxd"
build

# build libimobiledevice
cd "$base/libimobiledevice"
build

# build libzip
cd "$base/libzip"
rm -rf "$base/libzip/build"
mkdir -pv "$base/libzip/build"
cd "$base/libzip/build"
cmake "-DCMAKE_INSTALL_PREFIX=$PWD/output" '-DCMAKE_BUILD_TYPE=Release' '-DCMAKE_POSITION_INDEPENDENT_CODE=1' '-D_GLIBCXX_USE_CXX11_ABI=0' '-DD_GLIBCXX_USE_CXX11_ABI=0' '-DBUILD_SHARED_LIBS=0' ..
make install

# build zstd
cd "$base/zstd"
rm -rf "$base/zstd/build2"
mkdir -pv "$base/zstd/build2"
cd "$base/zstd/build2"
cmake "-DCMAKE_INSTALL_PREFIX=$PWD/output" '-DCMAKE_BUILD_TYPE=Release' '-DCMAKE_POSITION_INDEPENDENT_CODE=1' '-D_GLIBCXX_USE_CXX11_ABI=0' '-DD_GLIBCXX_USE_CXX11_ABI=0' '-DZSTD_BUILD_SHARED=0' '-DZSTD_BUILD_STATIC=1' '-DZSTD_BUILD_TESTS=0' '-DZSTD_BUILD_PROGRAMS=0' ../build/cmake
make install

cd "$base/ideviceinstaller"
export LIBS="-llzma -lz -lbz2 $base/zstd/build2/output/lib/libzstd.a"
build

otool -L "$base/ideviceinstaller/build/bin/ideviceinstaller"

exit
