//
//  ImageConversionStrategy.swift
//  NolockOCRClient
//
//  Strategy pattern for image conversion to handle different OS versions
//

import Foundation
#if canImport(ImageIO)
import ImageIO
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

// MARK: - Strategy Protocol

/// Protocol defining the image conversion strategy
public protocol ImageConversionStrategy {
    /// Convert HEIC/HEIF image to JPEG
    func convertToJPEG(from heicData: Data, quality: Double) throws -> Data
    
    /// Create JPEG destination and write image
    func createJPEGDestination(at url: URL, image: CGImage, quality: Double) throws
    
    /// Get JPEG type identifier string
    var jpegTypeIdentifier: String { get }
    
    /// Check if URL has HEIC/HEIF type (optional check)
    func isHEICByResourceType(url: URL) -> Bool
}

// MARK: - Modern Strategy (iOS 14.0+, macOS 11.0+)

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
class ModernImageConversionStrategy: ImageConversionStrategy {
    
    func convertToJPEG(from heicData: Data, quality: Double) throws -> Data {
        guard let imageSource = CGImageSourceCreateWithData(heicData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw OCRConversionError.failedToCreateImageFromHEIC
        }
        
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw OCRConversionError.failedToCreateJPEGDestination
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw OCRConversionError.failedToFinalizeJPEG
        }
        
        return data as Data
    }
    
    func createJPEGDestination(at url: URL, image: CGImage, quality: Double) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw OCRConversionError.failedToCreateJPEGDestination
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw OCRConversionError.failedToFinalizeJPEG
        }
    }
    
    var jpegTypeIdentifier: String {
        return UTType.jpeg.identifier
    }
    
    func isHEICByResourceType(url: URL) -> Bool {
        if let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
            let heicTypes = [UTType.heic.identifier, UTType.heif.identifier]
            return heicTypes.contains(typeIdentifier)
        }
        return false
    }
}

// MARK: - Legacy Strategy (Pre iOS 14.0, macOS 11.0)

class LegacyImageConversionStrategy: ImageConversionStrategy {
    
    func convertToJPEG(from heicData: Data, quality: Double) throws -> Data {
        guard let imageSource = CGImageSourceCreateWithData(heicData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw OCRConversionError.failedToCreateImageFromHEIC
        }
        
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            throw OCRConversionError.failedToCreateJPEGDestination
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw OCRConversionError.failedToFinalizeJPEG
        }
        
        return data as Data
    }
    
    func createJPEGDestination(at url: URL, image: CGImage, quality: Double) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            throw OCRConversionError.failedToCreateJPEGDestination
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw OCRConversionError.failedToFinalizeJPEG
        }
    }
    
    var jpegTypeIdentifier: String {
        return "public.jpeg"
    }
    
    func isHEICByResourceType(url: URL) -> Bool {
        // Legacy systems rely on file extension or header checking only
        return false
    }
}

// MARK: - Strategy Factory

/// Factory class to create appropriate strategy based on OS version
public class ImageConversionStrategyFactory {
    
    /// Shared instance with appropriate strategy for current OS
    public static let shared = ImageConversionStrategyFactory()
    
    /// The current strategy based on OS version
    public let strategy: ImageConversionStrategy
    
    private init() {
        #if canImport(UniformTypeIdentifiers)
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            self.strategy = ModernImageConversionStrategy()
        } else {
            self.strategy = LegacyImageConversionStrategy()
        }
        #else
        self.strategy = LegacyImageConversionStrategy()
        #endif
    }
    
    /// Convert HEIC data to JPEG data
    public func convertToJPEG(from heicData: Data, quality: Double) throws -> Data {
        return try strategy.convertToJPEG(from: heicData, quality: quality)
    }
    
    /// Create JPEG file at URL from CGImage
    public func createJPEGDestination(at url: URL, image: CGImage, quality: Double) throws {
        try strategy.createJPEGDestination(at: url, image: image, quality: quality)
    }
    
    /// Get JPEG type identifier for current platform
    public var jpegTypeIdentifier: String {
        return strategy.jpegTypeIdentifier
    }
    
    /// Check if file is HEIC by resource type (if supported)
    public func isHEICByResourceType(url: URL) -> Bool {
        return strategy.isHEICByResourceType(url: url)
    }
}