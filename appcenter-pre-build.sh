echo "Executing pre build script"

# Add Private CocoaPods
pod repo add NEXMO_PRIVATE_COCOAPODS https://RastriginSergey:$GITHUB_TOKEN@github.com/Vonage/PrivateCocoapodsSpecs

pip install awscli

aws s3 cp s3://nexmo-sdk-ci/branches/${APPCENTER_BRANCH}/sdk_versions/${CLIENT_VERSION}.env ./config.env

source ./config.env

printenv | grep "GITHUB_TOKEN"