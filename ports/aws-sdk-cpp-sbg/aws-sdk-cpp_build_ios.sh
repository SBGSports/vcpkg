#!/bin/bash

usage ()
{
	echo "usage: $0 [arm64, x86_64]"
	trap - INT TERM EXIT
	exit 127
}

VERSION="1.6.47"

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
	OSX_SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
else
	PLATFORM="iPhoneOS"
	OSX_SYSROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
fi

DEVELOPER=`xcode-select -print-path`
CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
SYSROOT_PATH=${CROSS_TOP}/SDKs/${CROSS_SDK}

echo $SYSROOT_PATH
OUTPUT=`pwd`/${IOS_ARCH}
mkdir ${IOS_ARCH}

# download postgres
if [ ! -e "aws-sdk-cpp" ]
then
    curl -L "https://github.com/aws/aws-sdk-cpp/tarball/${VERSION}" > "aws-sdk-cpp-${VERSION}.tar.gz"
    tar -zxf "aws-sdk-cpp-${VERSION}.tar.gz"
    mv aws-aws-sdk-cpp-09c22a5 aws-sdk-cpp-${VERSION}
fi

#git clone -b 1.6.47 https://github.com/aws/aws-sdk-cpp.git
cd aws-sdk-cpp-${VERSION}
mkdir build
cd build

BUILDING="core;cognito-idp;cognito-identity;access-management;batch;dynamodb;iam;identity-management;kinesis;lambda;rds;s3;sns;sqs;sts;transfer"

rm -r ./*
/Applications/CMake3.14.app/Contents/bin/cmake  -DCMAKE_OSX_SYSROOT="$OSX_SYSROOT" \
												-DCMAKE_OSX_ARCHITECTURES="$IOS_ARCH" \
												-DCMAKE_SYSTEM_NAME="Darwin" \
												-DCMAKE_SHARED_LINKER_FLAGS="-framework Foundation -lz -framework Security" \
												-DCMAKE_EXE_LINKER_FLAGS="-framework Foundation -framework Security" \
												-DCMAKE_PREFIX_PATH="$INCLIBS" \
												-DBUILD_SHARED_LIBS=ON \
												-DCMAKE_BUILD_TYPE="Release" \
												-DCMAKE_INSTALL_NAME_DIR="@rpath" \
												-DCMAKE_BUILD_WITH_INSTALL_RPATH="ON" \
												-DBUILD_ONLY="$BUILDING" \
												-DCUSTOM_MEMORY_MANAGEMENT=0 \
												-DCURL_INCLUDE_DIR="$INCLIBS/include" \
												-DCURL_LIBRARY_RELEASE="$INCLIBS/lib/libcurl.dylib" \
												-DZLIB_INCLUDE_DIR="$INCLIBS/include" \
												-DZLIB_LIBRARY_RELEASE="$INCLIBS/lib/libz.dylib" \
												-DCMAKE_INSTALL_PREFIX="$OUTPUT" \
												-DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++ -miphoneos-version-min=8.3" \
												../../aws-sdk-cpp-${VERSION}
make -j 8
make install
cd ../



