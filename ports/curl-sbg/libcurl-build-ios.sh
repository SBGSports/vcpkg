#!/bin/bash

# This script downlaods and builds the Mac, iOS and tvOS libcurl libraries with Bitcode enabled

# Credits:
#
# Felix Schwarz, IOSPIRIT GmbH, @@felix_schwarz.
#   https://gist.github.com/c61c0f7d9ab60f53ebb0.git
# Bochun Bai
#   https://github.com/sinofool/build-libcurl-ios
# Jason Cox, @jasonacox
#   https://github.com/jasonacox/Build-OpenSSL-cURL 
# Preston Jennings
#   https://github.com/prestonj/Build-OpenSSL-cURL 

set -e

# set trap to help debug any build errors
trap 'echo "** ERROR with Build - Check /tmp/curl*.log"; tail /tmp/curl*.log' INT TERM EXIT

usage ()
{
	echo "usage: $0 [arm64, x86_64]"
	trap - INT TERM EXIT
	exit 127
}

if [ "$1" == "-h" ]; then
	usage
fi

IOS_SDK_VERSION=""
IOS_MIN_SDK_VERSION="8.0"

CURL_VERSION="curl-7.64.0"

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

# Uncomment to compile without bitcode
#NOBITCODE="yes"

INCLIBS="${PWD}/../../installed/${IOS_TARGET}"
DEVELOPER=`xcode-select -print-path`
IPHONEOS_DEPLOYMENT_TARGET="6.0"

ls -la $LIBS
buildIOS()
{
	ARCH=$1
	BITCODE=$2

	pushd . > /dev/null
	cd "${CURL_VERSION}"
  
	if [[ "${ARCH}" == "x86_64" ]]; then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi

	if [[ "${BITCODE}" == "nobitcode" ]]; then
		CC_BITCODE_FLAG=""	
	else
		CC_BITCODE_FLAG="-fembed-bitcode"	
	fi

	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc"
	export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} ${CC_BITCODE_FLAG}"
	export LDFLAGS="-arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -Wl -s -Wl -Bsymbolic -Wl"
	export LIBS="-ldl"

   
	echo "Building ${CURL_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${ARCH} ${BITCODE}"

	if [[ "${ARCH}" == "arm64" ]]; then
		./configure -prefix="/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}" --disable-static --enable-shared -with-random=/dev/urandom --with-ssl=${INCLIBS} --with-libssh2=${INCLIBS} --with-zlib=${INCLIBS} --host="arm-apple-darwin" &> "/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log"
	else
		./configure -prefix="/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}" --disable-static --enable-shared -with-random=/dev/urandom --with-ssl=${INCLIBS} --with-libssh2=${INCLIBS} --with-zlib=${INCLIBS} --without-libidn2 --host="${ARCH}-apple-darwin" &> "/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log"
	fi

	make -j8 >> "/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	make install >> "/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	make clean >> "/tmp/${CURL_VERSION}-iOS-${ARCH}-${BITCODE}.log" 2>&1
	popd > /dev/null
}

echo "Cleaning up"

rm -rf "/tmp/${CURL_VERSION}-*"
rm -rf "/tmp/${CURL_VERSION}-*.log"
rm -rf curl

rm -rf "${CURL_VERSION}"

if [ ! -e ${CURL_VERSION}.tar.gz ]; then
	echo "Downloading ${CURL_VERSION}.tar.gz"
	curl -LO https://curl.haxx.se/download/${CURL_VERSION}.tar.gz
else
	echo "Using ${CURL_VERSION}.tar.gz"
fi

echo "Unpacking curl"
tar xfz "${CURL_VERSION}.tar.gz"

echo "Building iOS libraries ${IOS_ARCH} (nobitcode)"
buildIOS ${IOS_ARCH} "nobitcode"

cp -a "/tmp/${CURL_VERSION}-iOS-${IOS_ARCH}-nobitcode/" ./curl_${IOS_ARCH}

# change the rpath
install_name_tool -id  @rpath/libcurl.4.dylib ./curl_${IOS_ARCH}/lib/libcurl.4.dylib

#copy to the vcpkg installed folder 
cp -a ./curl_${IOS_ARCH}/include/ ../../installed/${IOS_TARGET}/include/
cp -a ./curl_${IOS_ARCH}/lib/ ../../installed/${IOS_TARGET}/lib/
cp -a ./curl_${IOS_ARCH}/share/ ../../installed/${IOS_TARGET}/share/
cp -a ./curl_${IOS_ARCH}/bin/ ../../installed/${IOS_TARGET}/bin/

#cat ../../installed/vcpkg/status vcpkg_status_update.txt > ../../installed/vcpkg/status_new
#cp ../../installed/vcpkg/status ../../installed/vcpkg/status_old
#cp ../../installed/vcpkg/status_new ../../installed/vcpkg/status

echo "Cleaning up"
#rm -rf /tmp/${CURL_VERSION}-*
rm -rf ${CURL_VERSION}

#reset trap
trap - INT TERM EXIT

echo "Done"




