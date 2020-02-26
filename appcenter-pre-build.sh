echo "Executing pre build script"

source ./config.env

# Add Private CocoaPods
pod repo add NEXMO_PRIVATE_COCOAPODS https://RastriginSergey:$GITHUB_TOKEN@github.com/Vonage/PrivateCocoapodsSpecs