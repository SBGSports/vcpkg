#!/bin/bash

set -e

usage ()
{
  echo "usage: $0 [arm64, x86_64]"
  trap - INT TERM EXIT
  exit 127
}

if [ "$1" == "-h" ]; then
  usage
fi

# edit these version numbers to suit your needs
VERSION=11.3
IOS=12.2
IOS_MIN_SDK_VERSION="7.1"

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

# to compile libpq for iOS, we need to use the Xcode SDK by saying -isysroot on the compile line
# there are two SDKs we need to use, the iOS device SDK (arm) and the simulator SDK (x86)

INCLIBS="${PWD}/../../installed/${IOS_TARGET}"
DEVELOPER=`xcode-select -print-path`
IPHONEOS_DEPLOYMENT_TARGET="6.0"

if [[ "${IOS_ARCH}" == "x86_64" ]]; then
  PLATFORM="iPhoneSimulator"
else
  PLATFORM="iPhoneOS"
fi

if [[ "${IOS_ARCH}" == "arm64" ]]; then
    ARM_CPP="-D__arm64__=1"
fi

export $PLATFORM
export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
export BUILD_TOOLS="${DEVELOPER}"
export CC="${BUILD_TOOLS}/usr/bin/gcc"
export CPP="${BUILD_TOOLS}/usr/bin/gcc"
export CFLAGS="-arch ${IOS_ARCH} -I${INCLIBS}/include -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} ${ARM_CPP}"
export LDFLAGS="-arch ${IOS_ARCH} -L${INCLIBS}/lib -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -Wl -s -Wl -Bsymbolic -Wl"
export LIBS="-ldl"

# create a staging directory (we need this for include files later on)
OUTPUT=`pwd`/"libpq/${IOS_ARCH}"
mkdir -p $OUTPUT

rm -fr postgresql-${VERSION}

# download postgres
if [ ! -e "postgresql-$VERSION" ]
then
    curl -OL "https://ftp.postgresql.org/pub/source/v${VERSION}/postgresql-${VERSION}.tar.gz"
    tar -zxf "postgresql-${VERSION}.tar.gz"
fi

cd postgresql-${VERSION}
chmod u+x ./configure

#apply the patch to remove the c pre-processor check (which was not behaving)
patch ./configure ../configure_ios_patch

# edit the darwin template to refer to the correct sdk
if [[ "${IOS_ARCH}" == "arm64" ]]; then
   sed "s/-sdk\ macosx/-sdk\ iphoneos/" ./src/template/darwin > temp.template
   cp temp.template ./src/template/darwin
else
   sed "s/-sdk\ macosx/-sdk\ iphonesimulator/" ./src/template/darwin > temp.template
   cp temp.template ./src/template/darwin
fi

#Build ARM64 library
if [[ "${IOS_ARCH}" == "arm64" ]]; then
   ./configure --host="arm-apple-darwin" --with-includes="${INCLIBS}/include" --with-libraries="${INCLIBS}/lib" --without-readline  --with-openssl --prefix="$OUTPUT"
else
   ./configure --host="${IOS_ARCH}-apple-darwin" --with-includes="${INCLIBS}/include" --with-libraries="${INCLIBS}/lib" --without-readline --with-openssl --prefix="$OUTPUT"
fi

make -C src/interfaces/libpq install
cd ..

#correct the rpath
install_name_tool -id  @rpath/libpq.5.dylib ./libpq/${IOS_ARCH}/lib/libpq.5.dylib

# copy the includes and the libs into the installed folder
cp -a ./libpq//${IOS_ARCH}/include/libpq-fe.h ../../installed/${IOS_TARGET}/include/
cp -a ./postgresql-${VERSION}/src/include/pg_config.h ../../installed/${IOS_TARGET}/include/
cp -a ./postgresql-${VERSION}/src/include/pg_config_ext.h ../../installed/${IOS_TARGET}/include/
cp -a ./postgresql-${VERSION}/src/include/postgres_ext.h  ../../installed/${IOS_TARGET}/include/
cp -a ./libpq/${IOS_ARCH}/lib/ ../../installed/${IOS_TARGET}/lib/

#cat ../../installed/vcpkg/status vcpkg_status_update.txt > ../../installed/vcpkg/status_new
#cp ../../installed/vcpkg/status ../../installed/vcpkg/status_old
#cp ../../installed/vcpkg/status_new ../../installed/vcpkg/status

echo "Cleaning up"
#rm -rf postgresql-${VERSION}
#rm -rf postgresql-${VERSION}.tar.
#ßrm index.html





