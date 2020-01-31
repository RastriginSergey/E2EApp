#!/bin/bash

podVersion=`pod --version`

if [ ! $podVersion ]; then
    echo ERROR: Failed to install Cocoapods
    exit 1
fi

echo "Cocoapods version is:" $podVersion

pod install

xcrun xcodebuild build-for-testing \
  -configuration Debug \
  -project E2EApp.xcodeproj \
  -sdk iphoneos \
  -scheme E2EApp \
  -derivedDataPath DerivedData
