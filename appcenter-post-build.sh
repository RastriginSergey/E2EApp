rm -rf DerivedData
xcrun xcodebuild build-for-testing \
  -configuration Debug \
  -workspace $APPCENTER_XCODE_PROJECT \
  -sdk iphoneos \
  -scheme $APPCENTER_XCODE_SCHEME \
  -derivedDataPath DerivedData

# version of devices 10.2
appcenter test run xcuitest
--app "My_Test/AppForE2E" \
--devices "My_Test/10-dot-2-1" \
--test-series "launch-tests" \
--locale "en_US" \
--build-dir "DerivedData/Build/Products/Debug-iphoneos" \
--token "1b2050ed79bfa481249056ef0970e19938771312"