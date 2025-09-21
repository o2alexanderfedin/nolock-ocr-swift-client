#!/usr/bin/swift

import Foundation

// Script to automate UI testing via AppleScript
let script = """
tell application "Simulator"
    activate
end tell

delay 1

tell application "System Events"
    tell process "Simulator"
        -- Click on Select Image button (center of the simulator window)
        click at {375, 410}

        delay 2

        -- Select first image from photo library
        click at {200, 300}

        delay 1

        -- Confirm selection
        click at {600, 100}
    end tell
end tell
"""

// Execute the AppleScript
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
task.arguments = ["-e", script]

do {
    try task.run()
    task.waitUntilExit()
    print("UI automation completed")
} catch {
    print("Error running automation: \(error)")
}