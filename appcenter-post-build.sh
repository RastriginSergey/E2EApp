echo "================================="
echo "ENVIRONEMNT VARIABLES"
env
echo "================================="

rm -rf DerivedData
xcrun xcodebuild build-for-testing \
  -configuration Debug \
  -workspace $APPCENTER_XCODE_PROJECT \
  -sdk iphoneos \
  -scheme $APPCENTER_XCODE_SCHEME \
  -derivedDataPath DerivedData


appcenter test run xcuitest \
--app "ashley.arthur-vonage.com/IOS-SDK_TEST" \
--devices "ashley.arthur-vonage.com/ios11" \
--test-series "master" \
--locale "en_US" \
--token "1b2050ed79bfa481249056ef0970e19938771312" \
--build-dir "DerivedData/Build/Products/Debug-iphoneos"