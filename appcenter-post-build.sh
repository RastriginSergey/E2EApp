#!/usr/bin/env bash

echo "post build script was executed"

env


appcenter test run xcuitest \
--app "ashley.arthur-vonage.com/IOS-SDK_TEST" \
--devices "ashley.arthur-vonage.com/ios11" \
--test-series "master" \
--locale "en_US" \
--token "1b2050ed79bfa481249056ef0970e19938771312" \
--build-dir "DerivedData/E2EApp-*/Build/Products/Debug-iphoneos"
