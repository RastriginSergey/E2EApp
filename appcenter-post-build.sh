#!/usr/bin/env bash

echo "post build script was executed"

pwd

ls -R ./DerivedData | awk '
/:$/&&f{s=$0;f=0}
/:$/&&!f{sub(/:$/,"");s=$0;f=1;next}
NF&&f{ print s"/"$0 }'


appcenter test run xcuitest \
--app "ashley.arthur-vonage.com/IOS-SDK_TEST" \
--devices "ashley.arthur-vonage.com/ios11" \
--test-series "master" \
--locale "en_US" \
--token "1b2050ed79bfa481249056ef0970e19938771312" \
--build-dir "DerivedData/E2EApp-*/Build/Products/Debug-iphoneos"
