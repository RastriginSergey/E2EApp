aws --version

aws s3 cp s3://nexmo-sdk-ci/bar.zip ./

ls
#rm -rf DerivedData
##xcrun xcodebuild build-for-testing \
##  -configuration Debug \
##  -workspace $APPCENTER_XCODE_PROJECT \
##  -sdk iphoneos \
##  -scheme $APPCENTER_XCODE_SCHEME \
##  -derivedDataPath DerivedData
##
##cd ./DerivedData/Build/Products
##
##zip -rX Products.zip *
##
##zipinfo Products.zip
#
#
## version of devices 10.2
##appcenter test run xcuitest \
##--app "My_Test/AppForE2E" \
##--devices "My_Test/10-dot-2-1" \
##--test-series "launch-tests" \
##--locale "en_US" \
##--build-dir "DerivedData/Build/Products/Debug-iphoneos" \
##--token "1b2050ed79bfa481249056ef0970e19938771312"
#
#
## versions 13, 12, 11 and 10
##appcenter test run xcuitest --app "My_Test/AppForE2E" --devices "My_Test/5-devices" --test-series "launch-tests" --locale "en_US" --build-dir "DerivedData/Build/Products/Debug-iphoneos" --token "1b2050ed79bfa481249056ef0970e19938771312"