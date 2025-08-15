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
    /// Get JPEG type identifier for the platform
    var jpegTypeIdentifier: String { get }
    
    /// Create JPEG destination and write image
    func createJPEGDestination(at url: URL, image: CGImage, quality: Double) throws
}

// MARK: - Shared Implementation (DRY)

extension ImageConversionStrategy {
    /// Common HEIC to CGImage conversion - shared by all strategies
    func createCGImage(from heicData: Data) throws -> CGImage {
        guard let imageSource = CGImageSourceCreateWithData(heicData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw OCRConversionError.failedToCreateImageFromHEIC
        }
        return cgImage
    }
    
    /// Common implementation for converting HEIC data to JPEG at a URL
    public func convertHEICToJPEG(heicURL: URL, quality: Double) throws -> URL {
        let heicData = try Data(contentsOf: heicURL)
        let cgImage = try createCGImage(from: heicData)
        
        let jpegURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ocr-converted-\(UUID().uuidString)")
            .appendingPathExtension("jpg")
        
        try createJPEGDestination(at: jpegURL, image: cgImage, quality: quality)
        return jpegURL
    }
}

// MARK: - Modern Strategy (iOS 14.0+, macOS 11.0+)

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
class ModernImageConversionStrategy: ImageConversionStrategy {
    
    var jpegTypeIdentifier: String {
        #if canImport(UniformTypeIdentifiers)
        return UTType.jpeg.identifier
        #else
        return "public.jpeg"
        #endif
    }
    
    func createJPEGDestination(at url: URL, image: CGImage, quality: Double) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            jpegTypeIdentifier as CFString,
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
}

// MARK: - Legacy Strategy (Pre iOS 14.0, macOS 11.0)

class LegacyImageConversionStrategy: ImageConversionStrategy {
    
    var jpegTypeIdentifier: String {
        return "public.jpeg"
    }
    
    func createJPEGDestination(at url: URL, image: CGImage, quality: Double) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            jpegTypeIdentifier as CFString,
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
    
    /// Convert HEIC file to JPEG (main public API)
    public func convertHEICToJPEG(heicURL: URL, quality: Double) throws -> URL {
        return try strategy.convertHEICToJPEG(heicURL: heicURL, quality: quality)
    }
    
    /// Create JPEG file at URL from CGImage (for internal use)
    internal func createJPEGDestination(at url: URL, image: CGImage, quality: Double) throws {
        try strategy.createJPEGDestination(at: url, image: image, quality: quality)
    }
}