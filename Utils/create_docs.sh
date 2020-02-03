 #!/bin/bash
 pushd $PWD/../

 echo "creating docs for version $1"
 echo "jazzy --objc --author Nexmo --author_url https://developer.nexmo.com --module-version $1  --umbrella-header NexmoClient/NexmoClient.h --framework-root . --module NexmoClient   --output docs"
 jazzy --objc --author Nexmo --author_url https://developer.nexmo.com --module-version $1  --umbrella-header NexmoClient/NexmoClient.h --framework-root . --module NexmoClient   --output docs --readme Utils/README.md

 popd