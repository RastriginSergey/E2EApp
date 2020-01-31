#!/bin/bash

xcrun xcodebuild build-for-testing \
  -configuration Debug \
  -project E2EApp.xcodeproj \
  -sdk iphoneos \
  -scheme E2EApp \
  -derivedDataPath DerivedData
