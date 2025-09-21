#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = '/Users/alexanderfedin/Projects/nolock.social/Nolock.social.apps/nolock-ocr-swift-client/MinimalOCRApp/MinimalOCRApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'MinimalOCRApp' }

if target.nil?
  puts "Target 'MinimalOCRApp' not found!"
  exit 1
end

# Add Swift Package Manager dependency
package_path = File.expand_path('../..', project_path)

# Create a framework reference for the local package
framework_ref = project.frameworks_group.new_file(package_path)
framework_ref.name = 'NolockOCRClient'
framework_ref.path = '../../'
framework_ref.source_tree = '<group>'

# Add to frameworks build phase
frameworks_phase = target.frameworks_build_phase
unless frameworks_phase.file_display_names.include?('NolockOCRClient')
  frameworks_phase.add_file_reference(framework_ref)
end

# Also add package reference (for newer Xcode format)
# This is stored differently in objectVersion 77 format
target.build_configurations.each do |config|
  config.build_settings['SWIFT_INCLUDE_PATHS'] ||= []
  unless config.build_settings['SWIFT_INCLUDE_PATHS'].include?(package_path)
    config.build_settings['SWIFT_INCLUDE_PATHS'] << package_path
  end
end

# Save the project
project.save

puts "✅ Successfully added NolockOCRClient package to MinimalOCRApp!"
puts "📦 Package URL: #{package_url}"