rm -rf DerivedData
xcrun xcodebuild build-for-testing \
  -configuration Debug \
  -workspace $APPCENTER_XCODE_PROJECT \
  -sdk iphoneos \
  -scheme $APPCENTER_XCODE_SCHEME \
  -derivedDataPath DerivedData


# set of devices (versions from 10.2 to 13.2)
#appcenter test run xcuitest --app "ashley.arthur-vonage.com/IOS-SDK_TEST" --devices "ashley.arthur-vonage.com/tier-2" --test-series "set-of-devices" --locale "en_US" --build-dir "DerivedData/Build/Products/Debug-iphoneos" --token "1b2050ed79bfa481249056ef0970e19938771312"

# ios 13.2 only
#appcenter test run xcuitest --app "ashley.arthur-vonage.com/IOS-SDK_TEST" --devices "ashley.arthur-vonage.com/ios11" --test-series "master" --locale "en_US" --build-dir "DerivedData/Build/Products/Debug-iphoneos" --token "1b2050ed79bfa481249056ef0970e19938771312"

# ios 11.0.3 only
appcenter test run xcuitest --app "ashley.arthur-vonage.com/IOS-SDK_TEST" --devices "ashley.arthur-vonage.com/11-dot-0-3" --test-series "set-of-devices" --locale "en_US" --build-dir "DerivedData/Build/Products/Debug-iphoneos" --token "1b2050ed79bfa481249056ef0970e19938771312"