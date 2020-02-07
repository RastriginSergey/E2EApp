rm -rf DerivedData
xcrun xcodebuild build-for-testing \
  -configuration Debug \
  -workspace $APPCENTER_XCODE_PROJECT \
  -sdk iphoneos \
  -scheme $APPCENTER_XCODE_SCHEME \
  -derivedDataPath DerivedData

appcenter test run xcuitest --app "ashley.arthur-vonage.com/IOS-SDK_TEST" --devices "ashley.arthur-vonage.com/tier-2" --test-series "set-of-devices" --locale "en_US" --build-dir "DerivedData/Build/Products/Debug-iphoneos" --token "1b2050ed79bfa481249056ef0970e19938771312"