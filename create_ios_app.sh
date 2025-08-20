#!/bin/bash

# Create minimal iOS app with Xcode command line
echo "Creating minimal iOS app..."

# Use Xcode command line to create project
xcodebuild -create-project MinimalOCR -projectType "iOS App"

echo "Opening in Xcode..."
open -a Xcode

# Tell Xcode to create new iOS app via AppleScript
osascript <<EOF
tell application "Xcode"
    activate
    delay 1
    tell application "System Events"
        -- Create new project
        keystroke "n" using {shift down, command down}
        delay 2
        
        -- Select iOS App
        key code 125 -- down arrow
        delay 0.5
        keystroke return
        delay 1
        
        -- Fill in details
        keystroke "MinimalOCRApp"
        keystroke tab
        keystroke tab
        keystroke "com.test"
        keystroke tab
        keystroke tab
        keystroke tab
        keystroke tab
        keystroke return
    end tell
end tell
EOF

echo "Add iOS_OCR_Test.swift to the project and run"