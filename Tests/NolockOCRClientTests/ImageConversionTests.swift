import XCTest
import Foundation
@testable import NolockOCRClient
#if canImport(ImageIO)
import ImageIO
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

final class ImageConversionTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Configure wrapper settings
        OCROperationsWrapper.jpegQuality = 0.95
        OCROperationsWrapper.autoCleanupTempFiles = true
    }
    
    // MARK: - HEIC Detection Tests
    
    func testHEICImageDetection() throws {
        guard let heicURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Access the private method through wrapper - since it's used internally when processing
        let originalURL = heicURL
        
        // Test by attempting HEIC conversion - this will only succeed if HEIC is detected correctly
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: originalURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        // Verify conversion worked
        XCTAssertTrue(FileManager.default.fileExists(atPath: jpegURL.path), 
                     "JPEG should exist after HEIC conversion")
        
        let jpegData = try Data(contentsOf: jpegURL)
        XCTAssertGreaterThan(jpegData.count, 0, "JPEG data should not be empty")
        
        // Verify JPEG magic bytes
        XCTAssertEqual(jpegData[0], 0xFF, "JPEG should start with 0xFF")
        XCTAssertEqual(jpegData[1], 0xD8, "JPEG should have 0xD8 as second byte")
    }
    
    // MARK: - Conversion Quality Tests
    
    func testJPEGQualityLevels() throws {
        guard let heicURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let qualityLevels: [Double] = [0.1, 0.3, 0.5, 0.7, 0.9, 1.0]
        var results: [(quality: Double, size: Int)] = []
        
        for quality in qualityLevels {
            let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: quality)
            defer { try? FileManager.default.removeItem(at: jpegURL) }
            
            let jpegData = try Data(contentsOf: jpegURL)
            results.append((quality: quality, size: jpegData.count))
            
            XCTAssertGreaterThan(jpegData.count, 0, "JPEG data should not be empty for quality \(quality)")
            
            // Verify it's a valid JPEG
            XCTAssertEqual(jpegData[0], 0xFF, "Should be valid JPEG at quality \(quality)")
            XCTAssertEqual(jpegData[1], 0xD8, "Should be valid JPEG at quality \(quality)")
        }
        
        // Sort by quality for analysis
        results.sort { $0.quality < $1.quality }
        
        print("JPEG Quality Analysis:")
        for result in results {
            print("  Quality \(String(format: "%.1f", result.quality)): \(result.size) bytes")
        }
        
        // Generally, higher quality should produce larger files
        // (with some exceptions at very high quality levels due to compression algorithms)
        let lowQuality = results.first!
        let highQuality = results.last!
        
        XCTAssertGreaterThan(highQuality.size, lowQuality.size, 
                           "Highest quality should generally produce larger files than lowest quality")
    }
    
    // MARK: - Conversion Strategy Tests
    
    func testImageConversionStrategyFactory() throws {
        guard let heicURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Test the factory directly
        let factory = ImageConversionStrategyFactory.shared
        let jpegURL = try factory.convertHEICToJPEG(heicURL: heicURL, quality: 0.8)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        // Verify conversion
        XCTAssertTrue(FileManager.default.fileExists(atPath: jpegURL.path), 
                     "Converted JPEG should exist")
        
        let jpegData = try Data(contentsOf: jpegURL)
        XCTAssertGreaterThan(jpegData.count, 0, "JPEG data should not be empty")
        
        print("ImageConversionStrategyFactory test:")
        print("  Original HEIC: \(try Data(contentsOf: heicURL).count) bytes")
        print("  Converted JPEG: \(jpegData.count) bytes")
        print("  Quality: 0.8")
    }
    
    // MARK: - Error Handling Tests
    
    func testConversionWithInvalidFile() {
        // Create a temporary file with invalid HEIC data
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("invalid_heic_\(UUID().uuidString)")
            .appendingPathExtension("heic")
        
        // Write some invalid data
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])
        
        do {
            try invalidData.write(to: tempURL)
            defer { try? FileManager.default.removeItem(at: tempURL) }
            
            // This should throw an error
            XCTAssertThrowsError(try OCROperationsWrapper.convertHEICToJPEG(heicURL: tempURL, quality: 0.95)) { error in
                print("Expected error for invalid HEIC file: \(error)")
            }
            
        } catch {
            XCTFail("Failed to write test file: \(error)")
        }
    }
    
    func testConversionWithNonExistentFile() {
        let nonExistentURL = URL(fileURLWithPath: "/tmp/does_not_exist.heic")
        
        XCTAssertThrowsError(try OCROperationsWrapper.convertHEICToJPEG(heicURL: nonExistentURL, quality: 0.95)) { error in
            print("Expected error for non-existent file: \(error)")
        }
    }
    
    // MARK: - Boundary Value Tests
    
    func testQualityBoundaryValues() throws {
        guard let heicURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Test minimum quality (0.0)
        let minQualityURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: 0.0)
        defer { try? FileManager.default.removeItem(at: minQualityURL) }
        
        let minQualityData = try Data(contentsOf: minQualityURL)
        XCTAssertGreaterThan(minQualityData.count, 0, "Should produce valid JPEG even at quality 0.0")
        
        // Test maximum quality (1.0)
        let maxQualityURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: 1.0)
        defer { try? FileManager.default.removeItem(at: maxQualityURL) }
        
        let maxQualityData = try Data(contentsOf: maxQualityURL)
        XCTAssertGreaterThan(maxQualityData.count, 0, "Should produce valid JPEG at quality 1.0")
        
        print("Quality boundary test:")
        print("  Quality 0.0: \(minQualityData.count) bytes")
        print("  Quality 1.0: \(maxQualityData.count) bytes")
    }
    
    // MARK: - Performance Tests
    
    func testConversionPerformance() throws {
        guard let heicURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Measure conversion performance
        measure {
            do {
                let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: 0.95)
                try? FileManager.default.removeItem(at: jpegURL)
            } catch {
                XCTFail("Conversion failed in performance test: \(error)")
            }
        }
    }
    
    func testMultipleConversionsPerformance() throws {
        guard let heicURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let numberOfConversions = 5
        
        measure {
            for i in 0..<numberOfConversions {
                do {
                    let quality = 0.5 + (Double(i) * 0.1) // Different qualities to avoid caching
                    let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: quality)
                    try? FileManager.default.removeItem(at: jpegURL)
                } catch {
                    XCTFail("Conversion \(i) failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - File Cleanup Tests
    
    func testAutoCleanupBehavior() throws {
        guard let heicURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Test with cleanup enabled
        OCROperationsWrapper.autoCleanupTempFiles = true
        
        let jpegURL1 = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: 0.95)
        
        // File should exist immediately after conversion
        XCTAssertTrue(FileManager.default.fileExists(atPath: jpegURL1.path), 
                     "JPEG should exist immediately after conversion")
        
        // Test with cleanup disabled
        OCROperationsWrapper.autoCleanupTempFiles = false
        
        let jpegURL2 = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL2) }
        
        // File should still exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: jpegURL2.path), 
                     "JPEG should exist when cleanup is disabled")
        
        // Clean up manually
        try? FileManager.default.removeItem(at: jpegURL1)
        
        // Reset to default
        OCROperationsWrapper.autoCleanupTempFiles = true
    }
}