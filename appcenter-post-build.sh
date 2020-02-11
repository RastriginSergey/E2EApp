echo "Executing post build script"

bash --version
which getopt

CI=1 /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install gnu-getopt
brew link --force gnu-getopt

appcenter test run xcuitest --app "My_Test/AppForE2E" \
--devices "My_Test/iphone-7-plus-13-dot-3-1" \
--test-series "master" \
--locale "en_US" \
--build-dir "DerivedData/E2EApp/Build/Products/Debug-iphonesimulator"
