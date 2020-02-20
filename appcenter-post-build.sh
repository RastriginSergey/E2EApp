echo "Executing post build script"

xcrun xcodebuild build-for-testing \
-configuration Debug \
-workspace E2EApp.xcworkspace \
-sdk iphoneos \
-scheme E2EApp \
-derivedDataPath DerivedData

cp $APPCENTER_OUTPUT_DIRECTORY/*.ipa ./DerivedData/Build/Products

(cd ./DerivedData/Build/Products; zip -rX Products.zip *)

aws s3 cp ./DerivedData/Build/Products/Products.zip s3://nexmo-sdk-ci/branches/${APPCENTER_BRANCH}/builds/${APPCENTER_BUILD_ID}.zip