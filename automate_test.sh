#!/bin/bash

echo "🤖 Starting automated OCR test..."

# Launch the app
echo "🤖 Launching app..."
xcrun simctl launch booted Ozone.MinimalOCRApp

# Wait for app to load
sleep 3

# Take a screenshot to confirm app is running
echo "🤖 Taking screenshot..."
xcrun simctl io booted screenshot /tmp/app_running.png

# Simulate tap on Select Image button (center of screen)
echo "🤖 Simulating tap on Select Image button..."
# Using AppleScript to simulate the tap
osascript <<EOF
tell application "Simulator"
    activate
end tell

delay 1

tell application "System Events"
    tell process "Simulator"
        set frontmost to true
        -- Click at the center where the button should be
        click at {390, 840}
    end tell
end tell
EOF

echo "🤖 Waiting for photo picker..."
sleep 3

# Take another screenshot
xcrun simctl io booted screenshot /tmp/photo_picker.png

echo "🤖 Test sequence completed"
echo "🤖 Check /tmp/app_debug.log for logs"

# Show the last logs
echo "🤖 Recent logs:"
tail -20 /tmp/app_debug.log