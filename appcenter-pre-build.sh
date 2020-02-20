echo "Executing post build script"

# Add Private CocoaPods
pod repo add NEXMO_PRIVATE_COCOAPODS https://RastriginSergey:$GITHUB_TOKEN@github.com/Vonage/PrivateCocoapodsSpecs

pip install awscli