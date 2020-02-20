echo "Executing post build script"

xcrun xcodebuild build-for-testing \
-configuration Debug \
-workspace E2EApp.xcworkspace \
-sdk iphoneos \
-scheme E2EApp \
-derivedDataPath DerivedData

(cd ./DerivedData/Build/Products; zip -rX Products.zip *)

aws s3 cp ./DerivedData/Build/Products/Products.zip s3://nexmo-sdk-ci/somethingsFOrNow.zip