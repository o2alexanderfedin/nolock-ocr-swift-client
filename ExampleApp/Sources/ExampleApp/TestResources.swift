//
//  TestResources.swift
//  ExampleApp
//
//  Helper to access embedded test resources
//

import Foundation

public struct TestResources {
    
    /// Get the URL for the embedded test HEIC image
    public static func getTestImageURL() -> URL? {
        return Bundle.module.url(forResource: "IMG_4171", withExtension: "heic")
    }
    
    /// Get the test image path with fallback to filesystem
    public static func getTestImagePath() -> String {
        // First try to get from bundle resources
        if let bundleURL = getTestImageURL() {
            return bundleURL.path
        }
        
        // Fallback to filesystem path (for backward compatibility)
        let fallbackPath = "/Users/alexanderfedin/Projects/nolock.social/Nolock.social.apps/nolock-ocr-swift-client/ExampleApp/IMG_4171.heic"
        if FileManager.default.fileExists(atPath: fallbackPath) {
            return fallbackPath
        }
        
        // Last resort - current directory
        return "IMG_4171.heic"
    }
    
    /// Copy embedded resource to temporary location if needed
    public static func prepareTestImage() throws -> URL {
        guard let resourceURL = getTestImageURL() else {
            // Fallback to filesystem
            let path = getTestImagePath()
            return URL(fileURLWithPath: path)
        }
        
        // Resource is already accessible
        return resourceURL
    }
}