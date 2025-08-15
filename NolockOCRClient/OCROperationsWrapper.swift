//
//  OCROperationsWrapper.swift
//  NolockOCRClient
//
//  Wrapper for OCROperationsAPI that automatically converts HEIC images to JPEG
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

/// Wrapper class for OCR operations that automatically handles HEIC to JPEG conversion
public class OCROperationsWrapper {
    
    /// JPEG compression quality (0.0 to 1.0)
    public static var jpegQuality: Double = 0.95
    
    /// Whether to automatically delete temporary JPEG files after processing
    public static var autoCleanupTempFiles: Bool = true
    
    /// Process check OCR with automatic HEIC conversion if needed
    /// - Parameter imageURL: URL to the image file (HEIC, JPEG, PNG, etc.)
    /// - Returns: CheckModelOcrResponse from the API
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func processCheckOcr(imageURL: URL) async throws -> CheckModelOcrResponse {
        let processURL = try await prepareImageForOCR(imageURL: imageURL)
        let shouldCleanup = processURL != imageURL && autoCleanupTempFiles
        
        defer {
            if shouldCleanup {
                try? FileManager.default.removeItem(at: processURL)
            }
        }
        
        return try await OCROperationsAPI.processCheckOcr(body: processURL)
    }
    
    /// Process receipt OCR with automatic HEIC conversion if needed
    /// - Parameter imageURL: URL to the image file (HEIC, JPEG, PNG, etc.)
    /// - Returns: ReceiptModelOcrResponse from the API
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func processReceiptOcr(imageURL: URL) async throws -> ReceiptModelOcrResponse {
        let processURL = try await prepareImageForOCR(imageURL: imageURL)
        let shouldCleanup = processURL != imageURL && autoCleanupTempFiles
        
        defer {
            if shouldCleanup {
                try? FileManager.default.removeItem(at: processURL)
            }
        }
        
        return try await OCROperationsAPI.processReceiptOcr(body: processURL)
    }
    
    /// Process check OCR with completion handler (for non-async contexts)
    /// - Parameters:
    ///   - imageURL: URL to the image file
    ///   - completion: Completion handler with result
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func processCheckOcr(imageURL: URL, completion: @escaping (Result<CheckModelOcrResponse, Error>) -> Void) {
        Task {
            do {
                let processURL = try await prepareImageForOCR(imageURL: imageURL)
                let shouldCleanup = processURL != imageURL && autoCleanupTempFiles
                
                OCROperationsAPI.processCheckOcrWithRequestBuilder(body: processURL)
                    .execute { result in
                        // Clean up temp file if needed
                        if shouldCleanup {
                            try? FileManager.default.removeItem(at: processURL)
                        }
                        
                        switch result {
                        case .success(let response):
                            completion(.success(response.body))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Process receipt OCR with completion handler (for non-async contexts)
    /// - Parameters:
    ///   - imageURL: URL to the image file
    ///   - completion: Completion handler with result
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func processReceiptOcr(imageURL: URL, completion: @escaping (Result<ReceiptModelOcrResponse, Error>) -> Void) {
        Task {
            do {
                let processURL = try await prepareImageForOCR(imageURL: imageURL)
                let shouldCleanup = processURL != imageURL && autoCleanupTempFiles
                
                OCROperationsAPI.processReceiptOcrWithRequestBuilder(body: processURL)
                    .execute { result in
                        // Clean up temp file if needed
                        if shouldCleanup {
                            try? FileManager.default.removeItem(at: processURL)
                        }
                        
                        switch result {
                        case .success(let response):
                            completion(.success(response.body))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Prepare image for OCR processing
    /// - Parameter imageURL: Original image URL
    /// - Returns: URL ready for OCR (original or converted JPEG)
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    private static func prepareImageForOCR(imageURL: URL) async throws -> URL {
        // Check if the file is HEIC
        if isHEICImage(url: imageURL) {
            return try convertHEICToJPEG(heicURL: imageURL, quality: jpegQuality)
        }
        
        // Return original URL for non-HEIC images
        return imageURL
    }
    
    /// Check if a file is HEIC format by reading file header
    /// - Parameter url: File URL to check
    /// - Returns: true if HEIC/HEIF, false otherwise
    private static func isHEICImage(url: URL) -> Bool {
        // Read file header to check magic bytes
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return false
        }
        defer { fileHandle.closeFile() }
        
        // Read first 12 bytes for HEIF container detection
        let headerData = fileHandle.readData(ofLength: 12)
        guard headerData.count >= 12 else {
            return false
        }
        
        // HEIF files start with an ftyp box
        // Bytes 4-7 should be "ftyp" (66 74 79 70)
        // Bytes 8-11 contain the major brand
        let ftypBytes = headerData.subdata(in: 4..<8)
        let ftypString = String(data: ftypBytes, encoding: .ascii)
        
        guard ftypString == "ftyp" else {
            return false
        }
        
        // Check the major brand (bytes 8-11)
        let brandBytes = headerData.subdata(in: 8..<12)
        let brandString = String(data: brandBytes, encoding: .ascii)
        
        // HEIC/HEIF major brands
        let heicBrands = [
            "heic",  // HEIC image
            "heix",  // HEIC image sequence
            "hevc",  // HEVC encoded
            "hevx",  // HEVC encoded sequence
            "heim",  // HEIC image derivation
            "heis",  // HEIC scalable
            "hevm",  // HEVC video
            "hevs",  // HEVC scalable video
            "mif1",  // HEIF image
            "msf1"   // HEIF image sequence
        ]
        
        if let brand = brandString, heicBrands.contains(brand) {
            return true
        }
        
        // Also check compatible brands (starting at byte 16)
        // Read more data to check compatible brands
        fileHandle.seek(toFileOffset: 0)
        let extendedData = fileHandle.readData(ofLength: 64)
        
        // Look for HEIC/HEIF brands in compatible brands section
        if extendedData.count >= 16 {
            let compatibleBrandsData = extendedData.subdata(in: 16..<min(extendedData.count, 64))
            let compatibleString = String(data: compatibleBrandsData, encoding: .ascii) ?? ""
            
            for brand in heicBrands {
                if compatibleString.contains(brand) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Convert HEIC image to JPEG
    /// - Parameters:
    ///   - heicURL: URL of the HEIC file
    ///   - quality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: URL of the converted JPEG file
    public static func convertHEICToJPEG(heicURL: URL, quality: Double) throws -> URL {
        // Read HEIC data
        let heicData = try Data(contentsOf: heicURL)
        
        // Create CGImageSource from HEIC data
        guard let imageSource = CGImageSourceCreateWithData(heicData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw OCRConversionError.failedToCreateImageFromHEIC
        }
        
        // Create temporary JPEG file URL
        let jpegURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ocr-converted-\(UUID().uuidString)")
            .appendingPathExtension("jpg")
        
        // Use strategy pattern for JPEG creation
        try ImageConversionStrategyFactory.shared.createJPEGDestination(
            at: jpegURL,
            image: cgImage,
            quality: quality
        )
        
        return jpegURL
    }
}

/// Errors that can occur during image conversion
public enum OCRConversionError: LocalizedError {
    case failedToCreateImageFromHEIC
    case failedToCreateJPEGDestination
    case failedToFinalizeJPEG
    
    public var errorDescription: String? {
        switch self {
        case .failedToCreateImageFromHEIC:
            return "Failed to create image from HEIC data"
        case .failedToCreateJPEGDestination:
            return "Failed to create JPEG destination"
        case .failedToFinalizeJPEG:
            return "Failed to finalize JPEG conversion"
        }
    }
}