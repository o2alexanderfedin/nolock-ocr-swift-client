#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

# Open the project
project_path = 'MinimalOCRApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Opened project: #{project_path}"

# Find the main target
target = project.targets.find { |t| t.name == 'MinimalOCRApp' }
if target.nil?
  puts "Error: Target 'MinimalOCRApp' not found"
  exit 1
end

puts "Found target: #{target.name}"

# Create a local Swift package reference
package_path = File.expand_path('.')
puts "Package path: #{package_path}"

# Check if package references already exist
existing_package = project.root_object.package_references.find do |ref|
  ref.is_a?(Xcodeproj::Project::Object::XCLocalSwiftPackageReference) &&
  ref.relative_path == '../..'
end

if existing_package
  puts "Package reference already exists"
  package_ref = existing_package
else
  puts "Creating new local package reference..."

  # Create local package reference
  package_ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  package_ref.relative_path = '../..'

  # Add to project's package references
  project.root_object.package_references ||= []
  project.root_object.package_references << package_ref

  puts "Added local package reference"
end

# Create package product dependency
existing_product = target.package_product_dependencies.find do |dep|
  dep.product_name == 'NolockOCRClient'
end

if existing_product
  puts "Package product dependency already exists"
else
  puts "Creating package product dependency..."

  product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product_dep.package = package_ref
  product_dep.product_name = 'NolockOCRClient'

  # Add to target's package product dependencies
  target.package_product_dependencies ||= []
  target.package_product_dependencies << product_dep

  puts "Added package product dependency to target"
end

# Also add to frameworks build phase
frameworks_phase = target.frameworks_build_phase
if frameworks_phase.nil?
  puts "Creating frameworks build phase..."
  frameworks_phase = project.new(Xcodeproj::Project::Object::PBXFrameworksBuildPhase)
  target.build_phases << frameworks_phase
end

# Check if already in frameworks
already_linked = frameworks_phase.file_display_names.any? do |name|
  name.include?('NolockOCRClient')
end

if already_linked
  puts "NolockOCRClient already in frameworks build phase"
else
  puts "Note: Framework will be automatically linked by SPM"
end

# Save the project
project.save
puts "✅ Project saved successfully!"

# Create/update Package.resolved file
package_resolved_path = 'MinimalOCRApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved'
FileUtils.mkdir_p(File.dirname(package_resolved_path))

package_resolved_content = {
  "object" => {
    "pins" => [
      {
        "package" => "NolockOCRClient",
        "repositoryURL" => "../..",
        "state" => {
          "branch" => nil,
          "revision" => nil,
          "version" => nil
        }
      }
    ]
  },
  "version" => 1
}

require 'json'
File.write(package_resolved_path, JSON.pretty_generate(package_resolved_content))
puts "✅ Created Package.resolved file"

puts "\n📱 Now you can build the project with:"
puts "  xcodebuild -project MinimalOCRApp.xcodeproj -scheme MinimalOCRApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build"