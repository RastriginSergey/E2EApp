echo "Executing post clone script"

pip install awscli

aws s3 cp s3://nexmo-sdk-ci/branches/${APPCENTER_BRANCH}/build-id/${APPCENTER_BUILD_ID}.env ./config.env

cat ./config.env

source ./config.env

printenv | grep "GITHUB_TOKEN"