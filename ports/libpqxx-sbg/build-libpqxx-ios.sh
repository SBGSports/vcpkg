#!/bin/bash

set -e

# edit these version numbers to suit your needs
VERSION=6.4.4
IOS=12.2

usage ()
{
  echo "usage: $0 [arm64, x86_64]"
  trap - INT TERM EXIT
  exit 127
}

if [ "$1" == "-h" ]; then
  usage
fi

if [ -z $1 ]; then
  IOS_ARCH="arm64"
else
  IOS_ARCH="$1"
fi


if [[ "${IOS_ARCH}" == "arm64" ]]; then
  IOS_TARGET="arm64-ios"
else
  IOS_TARGET="x64-ios-sim"
fi

INCLIBS="${PWD}/../../installed/${IOS_TARGET}"

if [[ "${IOS_ARCH}" == "x86_64" ]]; then
  PLATFORM="iPhoneSimulator"
else
  PLATFORM="iPhoneOS"
fi

PQLIB=libpq.5.dylib

DEVELOPER=`xcode-select -print-path`
CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
SYSROOT_PATH=${CROSS_TOP}/SDKs/${CROSS_SDK}

rm -fr cd libpqxx-${VERSION}

# download postgres
if [ ! -e "libpqxx-$VERSION" ]
then
    curl -L "https://github.com/jtv/libpqxx/tarball/${VERSION}" > "libpqxx-${VERSION}.tar.gz"
    tar -zxf "libpqxx-${VERSION}.tar.gz"
    mv jtv-libpqxx-593095f libpqxx-${VERSION}
fi


OUTPUT=`pwd`/${IOS_ARCH}
mkdir -p ${IOS_ARCH}

cd libpqxx-${VERSION}

#apply the patch to enable correct compilation
patch -p1 < ../patch_base_connectioncxx

mkdir -p build
cd build

#rm -r ./*
/Applications/CMake3.14.app/Contents/bin/cmake  -DCMAKE_OSX_SYSROOT="$SYSROOT_PATH" \
                        -DCMAKE_OSX_ARCHITECTURES="$IOS_ARCH" \
                        -DCMAKE_SYSTEM_NAME="Darwin" \
                        -DCMAKE_PREFIX_PATH="$INCLIBS" \
                        -DBUILD_TEST=OFF \
                        -DSKIP_PQXX_SHARED=ON \
                        -DCMAKE_BUILD_TYPE="Release" \
                        -DCMAKE_INSTALL_NAME_DIR="@rpath" \
                        -DCMAKE_BUILD_WITH_INSTALL_RPATH="ON" \
                        -DBUILD_ONLY="$BUILDING" \
                        -DPostgreSQL_INCLUDE_DIR="$INCLIBS/include" \
                        -DPostgreSQL_LIBRARY="$INCLIBS/lib/$PQLIB" \
                        -DPostgreSQL_TYPE_INCLUDE_DIR="$INCLIBS/include" \
                        -DCMAKE_INSTALL_PREFIX="$OUTPUT" \
                        -DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++ -miphoneos-version-min=8.3" \
                        ../../libpqxx-${VERSION}
make -j 8
make install
cd ../





