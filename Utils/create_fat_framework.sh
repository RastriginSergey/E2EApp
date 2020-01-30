#!/bin/bash

. script_include.sh

if [ "$1" == "" ]; then
	echo_red "No configuration specified. Usage: ./create_fat_framework [Debug/Release]"
	exit 1
fi

CONFIGURATION=$1

OUT_FOLDER="$PWD/../Output"
MERGED_FOLDER="$OUT_FOLDER/$CONFIGURATION"
FRAMEWORK_NAME="NexmoClient"

mkdir -p $MERGED_FOLDER

cp -rv $OUT_FOLDER/$CONFIGURATION-iphoneos/$FRAMEWORK_NAME.framework $MERGED_FOLDER/
lipo -create $OUT_FOLDER/$CONFIGURATION-iphoneos/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME $OUT_FOLDER/$CONFIGURATION-iphonesimulator/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME -o $MERGED_FOLDER/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME
