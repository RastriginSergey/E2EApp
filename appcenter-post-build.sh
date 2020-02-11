echo "Executing post build script"

xcrun  xcodebuild build-for-testing   -configuration Debug   -workspace E2EApp.xcworkspace  -sdk iphoneos   -scheme E2EApp   -derivedDataPath DerivedData
zip -r DerivedData DerivedData/ $APPCENTER_OUTPUT_DIRECTORY

REGION=eu-west-2
BUCKET=nexmo-sdk-ci
LOCAL_PATH=DerivedData.zip
REMOTE_PATH=DerivedData.zip
HMAC-SHA256s(){
	KEY="$1"
	DATA="$2"
	shift 2
	printf "$DATA" | openssl dgst -binary -sha256 -hmac "$KEY" | od -An -vtx1 | sed 's/[ \n]//g' | sed 'N;s/\n//'
}
HMAC-SHA256h(){
	KEY="$1"
	DATA="$2"
	shift 2
	printf "$DATA" | openssl dgst -binary -sha256 -mac HMAC -macopt "hexkey:$KEY" | od -An -vtx1 | sed 's/[ \n]//g' | sed 'N;s/\n//'
}
NOWDATE=$(date +%s)
REQUEST_TIME=$(date -r $NOWDATE +"%Y%m%dT%H%M%SZ")
EXPIRE=$(date -r $((NOWDATE + 30)) +"%Y-%m-%dT%H:%M:%SZ")
echo $EXPIRE
REQUEST_DATE=$(date -r $NOWDATE +"%Y%m%d")
REQUEST_SERVICE="s3"
AWS4SECRET="AWS4"$AWS_SECRET_KEY
ALGORITHM="AWS4-HMAC-SHA256"
ACL="private"


echo "uploading"
POST_POLICY='{"expiration":"'$EXPIRE'","conditions": [{"bucket":"'$BUCKET'" },{"acl":"'$ACL'" },["starts-with", "$key", "'$REMOTE_PATH'"],["eq", "$Content-Type", "application/x-zip-compressed"],{"x-amz-credential":"'$AWS_ACCESS_KEY'/'$REQUEST_DATE'/'$REGION'/'$REQUEST_SERVICE'/aws4_request"},{"x-amz-algorithm":"'$ALGORITHM'"},{"x-amz-date":"'$REQUEST_TIME'"}]}'
UPLOAD_REQUEST=$(printf "$POST_POLICY" | openssl base64 )
UPLOAD_REQUEST=$(echo -en $UPLOAD_REQUEST | sed "s/ //g")
SIGNATURE=$(HMAC-SHA256h $(HMAC-SHA256h $(HMAC-SHA256h $(HMAC-SHA256h $(HMAC-SHA256s $AWS4SECRET $REQUEST_DATE ) $REGION) $REQUEST_SERVICE) "aws4_request") $UPLOAD_REQUEST)
curl \
    -F "key=""$REMOTE_PATH" \
    -F "acl="$ACL"" \
    -F "Content-Type="application/x-zip-compressed"" \
    -F "x-amz-algorithm="$ALGORITHM"" \
    -F "x-amz-credential="$AWS_ACCESS_KEY/$REQUEST_DATE/$REGION/$REQUEST_SERVICE/aws4_request"" \
    -F "x-amz-date="$REQUEST_TIME"" \
    -F "Policy="$UPLOAD_REQUEST"" \
    -F "X-Amz-Signature="$SIGNATURE"" \
    -F "file=@"$LOCAL_PATH \
    https://$BUCKET.s3.amazonaws.com/
