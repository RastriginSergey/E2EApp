echo "Executing post build script"

getopt --version
brew install gnu-getopt
brew link --force gnu-getopt
getopt --version

appcenter test run xcuitest --app "My_Test/AppForE2E" \
--devices "My_Test/iphone-7-plus-13-dot-3-1" \
--test-series "master" \
--locale "en_US" \
--build-dir "DerivedData/E2EApp/Build/Products/Debug-iphonesimulator"
