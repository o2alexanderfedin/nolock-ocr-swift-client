//
//  MimeTypeStrategy.swift
//  NolockOCRClient
//
//  Strategy pattern for MIME type detection to handle different OS versions
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

// MARK: - Strategy Protocol

/// Protocol defining the MIME type detection strategy
public protocol MimeTypeStrategy {
    /// Get MIME type for a file extension
    func mimeType(for pathExtension: String) -> String
    
    /// Get MIME type for a URL
    func mimeType(for url: URL) -> String
}

// MARK: - Modern Strategy (iOS 14.0+, macOS 11.0+)

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
class ModernMimeTypeStrategy: MimeTypeStrategy {
    
    func mimeType(for pathExtension: String) -> String {
        #if canImport(UniformTypeIdentifiers)
        if let utType = UTType(filenameExtension: pathExtension) {
            return utType.preferredMIMEType ?? "application/octet-stream"
        }
        #endif
        return "application/octet-stream"
    }
    
    func mimeType(for url: URL) -> String {
        return mimeType(for: url.pathExtension)
    }
}

// MARK: - Legacy Strategy (Pre iOS 14.0, macOS 11.0)

class LegacyMimeTypeStrategy: MimeTypeStrategy {
    
    func mimeType(for pathExtension: String) -> String {
        #if canImport(MobileCoreServices) || canImport(CoreServices)
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue(),
           let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimetype as String
        }
        #endif
        return "application/octet-stream"
    }
    
    func mimeType(for url: URL) -> String {
        return mimeType(for: url.pathExtension)
    }
}

// MARK: - Strategy Factory

/// Factory class to create appropriate strategy based on OS version
public class MimeTypeStrategyFactory {
    
    /// Shared instance with appropriate strategy for current OS
    public static let shared = MimeTypeStrategyFactory()
    
    /// The current strategy based on OS version
    private let strategy: MimeTypeStrategy
    
    private init() {
        #if canImport(UniformTypeIdentifiers)
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            self.strategy = ModernMimeTypeStrategy()
        } else {
            self.strategy = LegacyMimeTypeStrategy()
        }
        #else
        self.strategy = LegacyMimeTypeStrategy()
        #endif
    }
    
    /// Get MIME type for a file extension
    public func mimeType(for pathExtension: String) -> String {
        return strategy.mimeType(for: pathExtension)
    }
    
    /// Get MIME type for a URL
    public func mimeType(for url: URL) -> String {
        return strategy.mimeType(for: url)
    }
}