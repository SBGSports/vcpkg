#!/bin/sh
LAME_FILE=lame-3.99.5.tar.gz
LAME_DIR=lame-3.99.5
IOS_MIN_SDK_VERSION="8.0"

rm -rf $LAME_DIR;

if ! [ -f $LAME_FILE ];then
	echo "downloading $LAME_FILE ..."
	wget $LAME_FILE https://github.com/wuqiong/mp3lame-for-iOS/raw/master/lame-3.99.5.tar.gz
	if [ $? != 0 ];then
		echo "downloading $LAME_FILE error ...";
		exit -1;
	else
		echo "downloading $LAME_FILE done ...";
	fi
fi

tar xf $LAME_FILE;

if [ $? != 0 ];then
	echo "extract $LAME_FILE error ...";
	rm -rf $LAME_FILE;
	rm -rf $LAME_DIR;
	exit -1;
fi

CONFIGURE_FLAGS="--enable-shared --disable-static --disable-frontend --enable-rpath='@rpath'"

ARCHS="arm64 x86_64"

# directories
SOURCE=${LAME_DIR}

SCRATCH="scratch-lame"
# must be an absolute path
THIN=`pwd`/"lame"

COMPILE="y"
LIPO="y"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		if [ "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    SIMULATOR="-mios-simulator-version-min=7.0"
            HOST=x86_64-apple-darwin
		else
		    PLATFORM="iPhoneOS"
		    SIMULATOR="-miphoneos-version-min=${IOS_MIN_SDK_VERSION}"
            HOST=arm-apple-darwin
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang -arch $ARCH"
		#AS="$CWD/$SOURCE/extras/gas-preprocessor.pl $CC"
		CFLAGS="-arch $ARCH $SIMULATOR"

		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"

		CC=$CC $CWD/$SOURCE/configure \
		    $CONFIGURE_FLAGS \
            --host=$HOST \
		    --prefix="$THIN/$ARCH" \
            CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"

		make -j4 install
		cd $CWD

		# change the rpath
		install_name_tool -id  @rpath/libmp3lame.0.dylib $THIN/$ARCH/lib/libmp3lame.0.dylib
	done
fi



rm -r $SCRATCH
rm -r $LAME_DIR





