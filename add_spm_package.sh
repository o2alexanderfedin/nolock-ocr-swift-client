#!/bin/bash

# Script to add local Swift Package to MinimalOCRApp
PROJECT_FILE="MinimalOCRApp/MinimalOCRApp.xcodeproj/project.pbxproj"

# Create a backup
cp "$PROJECT_FILE" "$PROJECT_FILE.bak"

# Add package reference using xcodebuild
cd MinimalOCRApp

# First, create a workspace if it doesn't exist
if [ ! -f "../NolockOCRClient.xcworkspace/contents.xcworkspacedata" ]; then
    echo "Creating workspace..."
    cat > ../NolockOCRClient.xcworkspace/contents.xcworkspacedata << EOF
<?xml version="1.0" encoding="UTF-8"?>
<Workspace version = "1.0">
   <FileRef location = "group:"></FileRef>
   <FileRef location = "group:MinimalOCRApp/MinimalOCRApp.xcodeproj"></FileRef>
</Workspace>
EOF
fi

# Use swift package to add the dependency
echo "Adding package dependency..."
swift package add-dependency --path ../ || true

# Alternative: Use xcodegen if available
if command -v xcodegen &> /dev/null; then
    echo "Using xcodegen..."
    cat > project.yml << EOF
name: MinimalOCRApp
options:
  bundleIdPrefix: com.nolock
packages:
  NolockOCRClient:
    path: ../
targets:
  MinimalOCRApp:
    type: application
    platform: iOS
    deploymentTarget: "15.0"
    sources: [MinimalOCRApp]
    dependencies:
      - package: NolockOCRClient
EOF
    xcodegen
else
    echo "xcodegen not found, skipping..."
fi

echo "Package dependency added. Please open the project in Xcode to complete the setup."