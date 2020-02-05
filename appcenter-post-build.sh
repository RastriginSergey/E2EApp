#!/usr/bin/env bash

echo "post build script was executed"
#
#pwd
#
#ls -lah
#
#dir_resolve()
#{
#cd "$1" 2>/dev/null || return $?  # cd to desired directory; if fail, quell any error messages but return exit status
#echo "`pwd -P`" # output full, link-resolved path
#}
#
#abs_path="`dir_resolve \"/Users/runner/Library/Developer/Xcode/DerivedData/E2EApp-*/DerivedData/Build/Products/Debug-iphoneos\"`"

appcenter test run xcuitest \
--app "ashley.arthur-vonage.com/IOS-SDK_TEST" \
--devices "ashley.arthur-vonage.com/ios11" \
--test-series "master" \
--locale "en_US" \
--token "1b2050ed79bfa481249056ef0970e19938771312" \
--build-dir $APPCENTER_OUTPUT_DIRECTORY

echo $APPCENTER_OUTPUT_DIRECTORY

ls -lah $APPCENTER_OUTPUT_DIRECTORY