#!/usr/bin/env bash

echo "post build script was executed"

appcenter test run xcuitest \
--app "ashley.arthur-vonage.com/IOS-SDK_TEST" \
--devices "ashley.arthur-vonage.com/ios11" \
--test-series "master" \
--locale "en_US" \
--build-dir DerivedData/Build/Products/Debug-iphoneos
