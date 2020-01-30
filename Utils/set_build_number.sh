#!/bin/bash

. script_include.sh

INFO_PLIST_FILE="$PWD/../NexmoClient/Info.plist"

if [ "$BUILD_NUMBER" == "" ]; then
	echo_red "BUILD_NUMBER env variable is not set. Aborting. Please Run from Jenkins job."
	exit 1
fi

git checkout -- $INFO_PLIST_FILE

PLIST_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $INFO_PLIST_FILE)

MAJOR_VERSION=$(echo $PLIST_VERSION | cut -d. -f1)
MINOR_VERSION=$(echo $PLIST_VERSION | cut -d. -f2)
PATCH_VERSION=$(echo $PLIST_VERSION | cut -d. -f3)

echo "Xcode bundle version: $PLIST_VERSION"
echo "Major: $MAJOR_VERSION"
echo "Minor: $MINOR_VERSION"
echo "Patch: $PATCH_VERSION"
echo "Build: $BUILD_NUMBER"

FINAL_VERSION="$MAJOR_VERSION.$MINOR_VERSION.$PATCH_VERSION.$BUILD_NUMBER"

echo "Version: $FINAL_VERSION"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $FINAL_VERSION" $INFO_PLIST_FILE