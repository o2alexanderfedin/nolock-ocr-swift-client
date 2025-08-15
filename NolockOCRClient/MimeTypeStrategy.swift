//
//  MimeTypeStrategy.swift
//  NolockOCRClient
//
//  Simplified MIME type detection utility
//

import Foundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
#if canImport(MobileCoreServices)
import MobileCoreServices
#endif
#if canImport(CoreServices)
import CoreServices
#endif

// MARK: - Simplified MIME Type Detection (KISS + DRY)

/// Simple utility for MIME type detection without unnecessary abstraction
public struct MimeTypeDetector {
    
    /// Get MIME type for a URL
    public static func mimeType(for url: URL) -> String {
        return mimeType(for: url.pathExtension)
    }
    
    /// Get MIME type for a file extension
    public static func mimeType(for pathExtension: String) -> String {
        // Try modern API first if available
        #if canImport(UniformTypeIdentifiers)
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            if let utType = UTType(filenameExtension: pathExtension) {
                return utType.preferredMIMEType ?? "application/octet-stream"
            }
        }
        #endif
        
        // Fallback to legacy API
        #if canImport(MobileCoreServices) || canImport(CoreServices)
        if let uti = UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension,
            pathExtension as NSString,
            nil
        )?.takeRetainedValue(),
           let mimetype = UTTypeCopyPreferredTagWithClass(
            uti,
            kUTTagClassMIMEType
        )?.takeRetainedValue() {
            return mimetype as String
        }
        #endif
        
        return "application/octet-stream"
    }
    
    private init() {} // Prevent instantiation
}

// For backward compatibility, keep the factory but simplify it
public class MimeTypeStrategyFactory {
    public static let shared = MimeTypeStrategyFactory()
    
    private init() {}
    
    public func mimeType(for pathExtension: String) -> String {
        return MimeTypeDetector.mimeType(for: pathExtension)
    }
    
    public func mimeType(for url: URL) -> String {
        return MimeTypeDetector.mimeType(for: url)
    }
}