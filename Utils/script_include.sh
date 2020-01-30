ARTIFACTORY_URL="https://artifactory.ess-dev.com/artifactory"
ARTIFACTORY_MAVEN="gradle-dev-local"
ARTIFACTORY_TEMPLATE="###ARTIFACTORYURL###/###ARTIFACTORYMAVEN###/com/nexmo/ios/NexmoClient/###VERSION###/NexmoClient-###VERSION###-iOS-###CONFIGURATION###.zip"
CDN_TEMPLATE="https://clientsdk.nexmocdn.com/ios/NexmoClient/###VERSION###/NexmoClient-###VERSION###-iOS-###CONFIGURATION###.zip"


function echo_green {
    printf '\e[0;32m%s\e[0m\n' "$1"
}

function echo_red {
    printf '\e[0;31m%s\e[0m\n' "$1"
}

function get_artifactory_artifact_path {

	if [ "$1" == "" ] || [ "$2" == "" ]; then
		echo_red "Wrong number of parameters.."
		echo_red "Usage: get_artifactory_artifact_path [Configuration] [Version]"
		return 1
	fi

	ARTIFACTORY_ARTIFACT_PATH="${ARTIFACTORY_TEMPLATE//###ARTIFACTORYURL###/$ARTIFACTORY_URL}"
	ARTIFACTORY_ARTIFACT_PATH="${ARTIFACTORY_ARTIFACT_PATH//###ARTIFACTORYMAVEN###/$ARTIFACTORY_MAVEN}"
	ARTIFACTORY_ARTIFACT_PATH="${ARTIFACTORY_ARTIFACT_PATH//###CONFIGURATION###/$1}"
	echo "${ARTIFACTORY_ARTIFACT_PATH//###VERSION###/$2}"
}

function get_cdn_artifact_path {

	if [ "$1" == "" ] || [ "$2" == "" ]; then
		echo_red "Wrong number of parameters.."
		echo_red "Usage: get_artifactory_artifact_path [Configuration] [Version]"
		return 1
	fi

	CDN_ARTIFACT_PATH="${CDN_TEMPLATE//###CONFIGURATION###/$1}"
	echo "${CDN_ARTIFACT_PATH//###VERSION###/$2}"
}