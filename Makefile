XCODEBUILD := xcodebuild
BUILD_FLAGS_IOS = -scheme $(SCHEME) -sdk iphoneos
BUILD_FLAGS_SIM = -scheme $(SCHEME) -sdk iphonesimulator

TEST_FLAGS = -scheme $(TEST_SCHEME) -destination 'platform=iOS Simulator,name=iPhone 7'

SCHEME ?= NexmoClient
TEST_SCHEME ?= NexmoClientTests


MINIRTC_VERSION ?= 0.01.127
OCMOCK_VERSION ?= 3.4
CLIENT_INFRASTRUCTURES_VERSION ?= 2.1.3
COCOA_LUMBERJACK_VERSION ?= 3.5.0.5

OCMOCK_FOLDER ?= Frameworks/OCMock
OCMOCK_VERSION_FILE = $(OCMOCK_FOLDER)/version
CURRENT_OCMOCK_VERSION = $(shell cat $(OCMOCK_VERSION_FILE))

MINIRTC_FOLDER ?= Frameworks/MiniRTC
MINIRTC_VERSION_FILE = $(MINIRTC_FOLDER)/version
CURRENT_MINIRTC_VERSION = $(shell cat $(MINIRTC_VERSION_FILE))

CLIENT_INFRASTRUCTURES_FOLDER ?= Frameworks/ClientInfrastructures
CLIENT_INFRASTRUCTURES_VERSION_FILE = $(CLIENT_INFRASTRUCTURES_FOLDER)/version
CURRENT_CLIENT_INFRASTRUCTURES_VERSION = $(shell cat $(CLIENT_INFRASTRUCTURES_VERSION_FILE))

COCOA_LUMBERJACK_FOLDER ?= Frameworks/CocoaNXMLumebrjack
COCOA_LUMBERJACK_VERSION_FILE = $(COCOA_LUMBERJACK_FOLDER)/version
CURRENT_COCOA_LUMBERJACK_VERSION = $(shell cat $(COCOA_LUMBERJACK_VERSION_FILE))

build: build_debug build_release

deps: minirtc ocmock clientinfrastructures cocoalumberjack
	@echo
	@echo "Done syncing dependencies."


cocoalumberjack:
	@echo
	@echo "-----------------------------------"
	@echo "Syncing CocoaNXMLumebrjack v$(COCOA_LUMBERJACK_VERSION)"
	@echo "-----------------------------------"

ifneq ($(COCOA_LUMBERJACK_VERSION),$(CURRENT_COCOA_LUMBERJACK_VERSION))
	@echo "Wrong or non-existing CocoaLumebrjack version. Downloading v$(COCOA_LUMBERJACK_VERSION) from Artifactory"
	@rm -rf $(COCOA_LUMBERJACK_FOLDER)
	@mkdir -p $(COCOA_LUMBERJACK_FOLDER)
	@curl -N -L -f -s --show-error https://artifactory.ess-dev.com/artifactory/gradle-dev-local/com/nexmo/ios/CocoaNXMLumberjack/$(COCOA_LUMBERJACK_VERSION)/CocoaNXMLumberjack-$(COCOA_LUMBERJACK_VERSION)-iOS-Release.zip -o cocoanxmlumberjack.zip
	@unzip cocoanxmlumberjack.zip -d $(COCOA_LUMBERJACK_FOLDER)
	@echo "$(COCOA_LUMBERJACK_VERSION)" > $(COCOA_LUMBERJACK_VERSION_FILE)
	@rm cocoanxmlumberjack.zip
else
	@echo "Already have current CocoaNXMLumebrjack version"
endif


clientinfrastructures:
	@echo
	@echo "-----------------------------------"
	@echo "Syncing ClientInfrastructures v$(CLIENT_INFRASTRUCTURES_VERSION)"
	@echo "-----------------------------------"

ifneq ($(CLIENT_INFRASTRUCTURES_VERSION),$(CURRENT_CLIENT_INFRASTRUCTURES_VERSION))
	@echo "Wrong or non-existing MiniRTC version. Downloading v$(CLIENT_INFRASTRUCTURES_VERSION) from Artifactory"
	@rm -rf $(CLIENT_INFRASTRUCTURES_FOLDER)
	@mkdir -p $(CLIENT_INFRASTRUCTURES_FOLDER)

	@curl -N -L -f -s --show-error https://artifactory.ess-dev.com/artifactory/gradle-dev-local/com/nexmo/ios/ClientInfrastructures/$(CLIENT_INFRASTRUCTURES_VERSION)/ClientInfrastructures-$(CLIENT_INFRASTRUCTURES_VERSION)-iOS-Release.zip -o clientinfrastructures.zip
	@unzip clientinfrastructures.zip -d $(CLIENT_INFRASTRUCTURES_FOLDER)
	@echo "$(CLIENT_INFRASTRUCTURES_VERSION)" > $(CLIENT_INFRASTRUCTURES_VERSION_FILE)
	@rm clientinfrastructures.zip
else
	@echo "Already have current ClientInfrastructures version"
endif


minirtc:
	@echo
	@echo "-----------------------------------"
	@echo "Syncing MiniRTC v$(MINIRTC_VERSION)"
	@echo "-----------------------------------"

ifneq ($(MINIRTC_VERSION),$(CURRENT_MINIRTC_VERSION))
	@echo "Wrong or non-existing MiniRTC version. Downloading v$(MINIRTC_VERSION) from Artifactory"
	@rm -rf $(MINIRTC_FOLDER)
	@mkdir -p $(MINIRTC_FOLDER)

	@curl -N -L -f -s --show-error https://artifactory.ess-dev.com/artifactory/gradle-dev-local/com/nexmo/ios/MiniRTC/$(MINIRTC_VERSION)/MiniRTC-$(MINIRTC_VERSION)-iOS-Release.zip -o minirtc.zip
	@unzip minirtc.zip -d $(MINIRTC_FOLDER)
	@echo "$(MINIRTC_VERSION)" > $(MINIRTC_VERSION_FILE)
	@rm minirtc.zip
else
	@echo "Already have current MiniRTC version"
endif

ocmock:
	@echo
	@echo "---------------------------------"
	@echo "Syncing OCMock v$(OCMOCK_VERSION)"
	@echo "---------------------------------"

ifneq ($(OCMOCK_VERSION),$(CURRENT_OCMOCK_VERSION))
	@echo "Wrong or non-existing OCMock version. Downloading v$(OCMOCK_VERSION) from Github"
	@rm -rf $(OCMOCK_FOLDER)
	@mkdir -p $(OCMOCK_FOLDER)

	@curl -N -L -f -s --show-error https://github.com/erikdoe/ocmock/releases/download/v$(OCMOCK_VERSION)/ocmock-$(OCMOCK_VERSION).dmg -o ocmock.dmg
	
	@hdiutil attach -readonly -mountpoint ./ocmock ocmock.dmg 
	@cp -Rv ./ocmock/* $(OCMOCK_FOLDER)
	@hdiutil detach -force ./ocmock
	@rm ocmock.dmg

	@echo "$(OCMOCK_VERSION)" > $(OCMOCK_VERSION_FILE)
else
	@echo "Already have current OCMock version"
endif

clean:
	@echo
	@echo "--------"
	@echo "Cleaning"
	@echo "--------"
	$(XCODEBUILD) clean $(BUILD_FLAGS)

build_debug: deps
	@echo
	@echo "------------------------------"
	@echo "Building Debug Framework (iOS)"
	@echo "------------------------------"
	$(XCODEBUILD) build $(BUILD_FLAGS_IOS) -configuration Debug

	@echo
	@echo "------------------------------------"
	@echo "Building Debug Framework (Simulator)"
	@echo "------------------------------------"
	$(XCODEBUILD) build $(BUILD_FLAGS_SIM) -configuration Debug

	@echo
	@echo "------------------------"
	@echo "Merging Debug Frameworks"
	@echo "------------------------"
	@cd utils; ./create_fat_framework.sh Debug

build_release: deps
	@echo
	@echo "--------------------------------"
	@echo "Building Release Framework (iOS)"
	@echo "--------------------------------"
	$(XCODEBUILD) build $(BUILD_FLAGS) -configuration Release

	@echo
	@echo "--------------------------------------"
	@echo "Building Release Framework (Simulator)"
	@echo "--------------------------------------"
	$(XCODEBUILD) build $(BUILD_FLAGS_SIM) -configuration Release

	@echo
	@echo "--------------------------"
	@echo "Merging Release Frameworks"
	@echo "--------------------------"
	@cd utils; ./create_fat_framework.sh Release

test: deps
	@echo
	@echo "-------------"
	@echo "Running tests"
	@echo "-------------"
	$(XCODEBUILD) test $(TEST_FLAGS)

release_internal: clean build
	@echo
	@echo "-----------------------------"
	@echo "Building For Internal Release"
	@echo "-----------------------------"
	@cd utils ; ./set_build_number.sh
	@cd utils ; ./publish_to_artifactory.sh
	@cd utils ; ./release_version.sh

release_external: clean build
	@echo
	@echo "--------------------"
	@echo "Building For Release"
	@echo "--------------------"
	@cd utils ; ./set_release_number.sh
	@cd utils ; ./publish_to_artifactory.sh
	@cd utils ; ./release_version.sh

