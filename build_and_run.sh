#!/bin/bash
set -e

echo "Building and running MinimalOCRApp..."

# Build the NolockOCRClient package first
echo "Step 1: Building NolockOCRClient package for arm64..."
cd /Users/alexanderfedin/Projects/nolock.social/Nolock.social.apps/nolock-ocr-swift-client
swift build -c debug --arch arm64

# Build the iOS app
echo "Step 2: Building MinimalOCRApp for arm64 iOS Simulator..."
cd MinimalOCRApp

# Clean previous builds
rm -rf build DerivedData

# Build with local package path
xcodebuild \
  -scheme MinimalOCRApp \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath ./DerivedData \
  ARCHS=arm64 \
  VALID_ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  EXCLUDED_ARCHS="x86_64 i386" \
  SWIFT_PACKAGE_DIR="../" \
  build

# Install on simulator
echo "Step 3: Installing app on simulator..."
APP_PATH="./DerivedData/Build/Products/Debug-iphonesimulator/MinimalOCRApp.app"
SIMULATOR_ID="A1D889A3-9542-4675-8B1D-B1A0AF1EF758"

# Boot simulator if needed
xcrun simctl boot $SIMULATOR_ID 2>/dev/null || true
sleep 2

# Install the app
xcrun simctl install $SIMULATOR_ID "$APP_PATH"

# Launch the app
echo "Step 4: Launching app..."
xcrun simctl launch $SIMULATOR_ID com.nolock.MinimalOCRApp

echo "App launched successfully!"