#! /usr/bin/env bash
#
# *  Author : WangBoJing , email : 1989wangbojing@gmail.com
# * 
# *  Copyright Statement:
# *  --------------------
# *  This software is protected by Copyright and the information contained
# *  herein is confidential. The software may not be copied and the information
# *  contained herein may not be used or disclosed except with the written
# *  permission of Author. (C) 2016
# * 
# *
# 
#****       *****
#  ***        *
#  ***        *                         *               *
#  * **       *                         *               *
#  * **       *                         *               *
#  *  **      *                        **              **
#  *  **      *                       ***             ***
#  *   **     *       ******       ***********     ***********    *****    *****
#  *   **     *     **     **          **              **           **      **
#  *    **    *    **       **         **              **           **      *
#  *    **    *    **       **         **              **            *      *
#  *     **   *    **       **         **              **            **     *
#  *     **   *            ***         **              **             *    *
#  *      **  *       ***** **         **              **             **   *
#  *      **  *     ***     **         **              **             **   *
#  *       ** *    **       **         **              **              *  *
#  *       ** *   **        **         **              **              ** *
#  *        ***   **        **         **              **               * *
#  *        ***   **        **         **     *        **     *         **
#  *         **   **        **  *      **     *        **     *         **
#  *         **    **     ****  *       **   *          **   *          *
#*****        *     ******   ***         ****            ****           *
#                                                                       *
#                                                                      *
#                                                                  *****
#                                                                  ****
#
# This script is based on projects below
# https://github.com/wangbojing/NattyServer

#--------------------
echo "===================="
echo "[*] check host"
echo "===================="
set -e


FF_XCRUN_DEVELOPER=`xcode-select -print-path`
if [ ! -d "$FF_XCRUN_DEVELOPER" ]; then
  echo "xcode path is not set correctly $FF_XCRUN_DEVELOPER does not exist (most likely because of xcode > 4.3)"
  echo "run"
  echo "sudo xcode-select -switch <xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

case $FF_XCRUN_DEVELOPER in  
     *\ * )
           echo "Your Xcode path contains whitespaces, which is not supported."
           exit 1
          ;;
esac


#--------------------
# include


#--------------------
# common defines
FF_ARCH=$1
if [ -z "$FF_ARCH" ]; then
    echo "You must specific an architecture 'armv7, armv7s, arm64, i386, x86_64, ...'.\n"
    exit 1
fi


FF_BUILD_ROOT=`pwd`
FF_TAGET_OS="darwin"


# natty build params
export COMMON_FF_CFG_FLAGS=

NATTY_CFG_FLAGS=
NATTY_EXTRA_CFLAGS=
NATTY_CFG_CPU=

# i386, x86_64
NATTY_CFG_FLAGS_SIMULATOR=

# armv7, armv7s, arm64
NATTY_CFG_FLAGS_ARM=
NATTY_CFG_FLAGS_ARM="iphoneos-cross"

echo "build_root: $FF_BUILD_ROOT"

#--------------------
echo "===================="
echo "[*] config arch $FF_ARCH"
echo "===================="

FF_BUILD_NAME="unknown"
FF_XCRUN_PLATFORM="iPhoneOS"
FF_XCRUN_OSVERSION=
FF_GASPP_EXPORT=
FF_XCODE_BITCODE=

if [ "$FF_ARCH" = "i386" ]; then
    FF_BUILD_NAME="natty-i386"
    FF_XCRUN_PLATFORM="iPhoneSimulator"
    FF_XCRUN_OSVERSION="-mios-simulator-version-min=6.0"
    NATTY_CFG_FLAGS="darwin-i386-cc $NATTY_CFG_FLAGS"
elif [ "$FF_ARCH" = "x86_64" ]; then
    FF_BUILD_NAME="natty-x86_64"
    FF_XCRUN_PLATFORM="iPhoneSimulator"
    FF_XCRUN_OSVERSION="-mios-simulator-version-min=7.0"
    NATTY_CFG_FLAGS="darwin64-x86_64-cc $NATTY_CFG_FLAGS"
elif [ "$FF_ARCH" = "armv7" ]; then
    FF_BUILD_NAME="natty-armv7"
    FF_XCRUN_OSVERSION="-miphoneos-version-min=6.0"
    FF_XCODE_BITCODE="-fembed-bitcode"
    NATTY_CFG_FLAGS="$NATTY_CFG_FLAGS_ARM $NATTY_CFG_FLAGS"
#    NATTY_CFG_CPU="--cpu=cortex-a8"
elif [ "$FF_ARCH" = "armv7s" ]; then
    FF_BUILD_NAME="natty-armv7s"
    NATTY_CFG_CPU="--cpu=swift"
    FF_XCRUN_OSVERSION="-miphoneos-version-min=6.0"
    FF_XCODE_BITCODE="-fembed-bitcode"
    NATTY_CFG_FLAGS="$NATTY_CFG_FLAGS_ARM $NATTY_CFG_FLAGS"
elif [ "$FF_ARCH" = "arm64" ]; then
    FF_BUILD_NAME="natty-arm64"
    FF_XCRUN_OSVERSION="-miphoneos-version-min=7.0"
    FF_XCODE_BITCODE="-fembed-bitcode"
    NATTY_CFG_FLAGS="$NATTY_CFG_FLAGS_ARM $NATTY_CFG_FLAGS"
    FF_GASPP_EXPORT="GASPP_FIX_XCODE5=1"
else
    echo "unknown architecture $FF_ARCH";
    exit 1
fi

echo "build_name: $FF_BUILD_NAME"
echo "platform:   $FF_XCRUN_PLATFORM"
echo "osversion:  $FF_XCRUN_OSVERSION"

#--------------------
echo "===================="
echo "[*] make ios toolchain $FF_BUILD_NAME"
echo "===================="


FF_BUILD_SOURCE="$FF_BUILD_ROOT/$FF_BUILD_NAME"
FF_BUILD_PREFIX="$FF_BUILD_ROOT/build/$FF_BUILD_NAME/output"

mkdir -p $FF_BUILD_PREFIX


FF_XCRUN_SDK=`echo $FF_XCRUN_PLATFORM | tr '[:upper:]' '[:lower:]'`
FF_XCRUN_SDK_PLATFORM_PATH=`xcrun -sdk $FF_XCRUN_SDK --show-sdk-platform-path`
FF_XCRUN_SDK_PATH=`xcrun -sdk $FF_XCRUN_SDK --show-sdk-path`
FF_XCRUN_CC="xcrun -sdk $FF_XCRUN_SDK clang"

export CROSS_TOP="$FF_XCRUN_SDK_PLATFORM_PATH/Developer"
export CROSS_SDK=`echo ${FF_XCRUN_SDK_PATH/#$CROSS_TOP\/SDKs\//}`
export BUILD_TOOL="$FF_XCRUN_DEVELOPER"
export CC="$FF_XCRUN_CC -arch $FF_ARCH $FF_XCRUN_OSVERSION"

echo "build_source: $FF_BUILD_SOURCE"
echo "build_prefix: $FF_BUILD_PREFIX"
echo "CROSS_TOP: $CROSS_TOP"
echo "CROSS_SDK: $CROSS_SDK"
echo "BUILD_TOOL: $BUILD_TOOL"
echo "CC: $CC"

#--------------------
echo "\n--------------------"
echo "[*] configurate natty"
echo "--------------------"

NATTY_CFG_FLAGS="$NATTY_CFG_FLAGS $FF_XCODE_BITCODE"
NATTY_CFG_FLAGS="$NATTY_CFG_FLAGS --nattydir=$FF_BUILD_PREFIX"

# xcode configuration
export DEBUG_INFORMATION_FORMAT=dwarf-with-dsym

cd $FF_BUILD_SOURCE
if [ -f "./Makefile" ]; then
    echo 'reuse configure'
else
    echo "config: $NATTY_CFG_FLAGS"
    ./Configure \
        $NATTY_CFG_FLAGS
    make clean
fi

#--------------------
echo "\n--------------------"
echo "[*] compile natty"
echo "--------------------"
set +e
make
#make install_sw
