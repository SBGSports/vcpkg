#!/bin/sh

# directories
FF_VERSION="3.3"
#FF_VERSION="snapshot-git"
if [[ $FFMPEG_VERSION != "" ]]; then
  FF_VERSION=$FFMPEG_VERSION
fi
SOURCE="ffmpeg-$FF_VERSION"
SCRATCH="scratch"
# must be an absolute path
THIN=`pwd`/"ffmpeg"

# absolute path to x264 library
#X264=`pwd`/fat-x264
#FDK_AAC=`pwd`/../fdk-aac-build-script-for-iOS/fdk-aac-ios

CONFIGURE_FLAGS="--install-name-dir='@rpath'  --enable-cross-compile --disable-debug --disable-programs \
                 --disable-doc --enable-pic --disable-static --enable-shared --disable-bzlib --disable-iconv --disable-libopenjpeg --disable-zlib \
                 --enable-asm --enable-pthreads --enable-openssl --disable-outdev=sdl2 --disable-sdl2"

LAMEMP3=`pwd`/lame

CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libmp3lame"


# avresample
#CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample"

ARCHS="arm64 x86_64"
COMPILE="y"
LIPO="y"

DEPLOYMENT_TARGET="8.0"

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
	if [ ! `which yasm` ]
	then
		echo 'Yasm not found'
		if [ ! `which brew` ]
		then
			echo 'Homebrew not found. Trying to install...'
                        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
				|| exit 1
		fi
		echo 'Trying to install Yasm...'
		brew install yasm || exit 1
	fi
	if [ ! `which gas-preprocessor.pl` ]
	then
		echo 'gas-preprocessor.pl not found. Trying to install...'
		(curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
			-o /usr/local/bin/gas-preprocessor.pl \
			&& chmod +x /usr/local/bin/gas-preprocessor.pl) \
			|| exit 1
	fi

	if [ ! -r $SOURCE ]
	then
		echo 'FFmpeg source not found. Trying to download...'
		#curl http://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj || exit 1
        curl -L "https://github.com/SBGSports/FFmpeg/tarball/sbg" > "ffmpeg.tar.gz"
        tar -zxf "ffmpeg.tar.gz"
        mv SBGSports-FFmpeg-0d08f2e $SOURCE
	fi

    # apply SBG patch
	cd $SOURCE

	#patch -p1 < ../sbg_commits.patch
	patch -p1 < ../find_openssl_configure.patch
	cd ../

	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"
		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
		    OPENSSL=`pwd`/../../../../installed/x64-ios-sim
		else
		    PLATFORM="iPhoneOS"
		    CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET"
		    OPENSSL=`pwd`/../../../../installed/arm64-ios
		    if [ "$ARCH" = "arm64" ]
		    then
		        EXPORT="GASPP_FIX_XCODE5=1"
		    fi
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang"

		# force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
		if [ "$ARCH" = "arm64" ]
		then
		    AS="gas-preprocessor.pl -arch aarch64 -- $CC"
		else
		    AS="gas-preprocessor.pl -- $CC"
		fi

		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"

		CFLAGS="$CFLAGS -I$LAMEMP3/$ARCH/include -I$OPENSSL/include"
 		LDFLAGS="$LDFLAGS -L$LAMEMP3/$ARCH/lib -L$OPENSSL/lib"

		TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
		    --target-os=darwin \
		    --arch=$ARCH \
		    --cc="$CC" \
		    --as="$AS" \
		    $CONFIGURE_FLAGS \
		    --extra-cflags="$CFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    --prefix="$THIN/$ARCH" \
		|| exit 1

		make -j4 install $EXPORT || exit 1
		cd $CWD
	done
fi

rm $SOURCE
echo Done
