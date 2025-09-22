import XCTest
import Foundation
@testable import NolockOCRClient

/// Tests for iOS-specific HEIC to JPEG conversion functionality
final class ImageConversionTests: XCTestCase {

    /// Test HEIC format detection and conversion
    func testHEICToJPEGConversion() throws {
        guard let heicURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }

        // Convert HEIC to JPEG
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }

        // Verify conversion worked
        XCTAssertTrue(FileManager.default.fileExists(atPath: jpegURL.path),
                     "JPEG should exist after conversion")

        let jpegData = try Data(contentsOf: jpegURL)
        XCTAssertGreaterThan(jpegData.count, 0, "JPEG data should not be empty")

        // Verify JPEG magic bytes
        XCTAssertEqual(jpegData[0], 0xFF, "JPEG should start with 0xFF")
        XCTAssertEqual(jpegData[1], 0xD8, "JPEG should have 0xD8 as second byte")
    }

    /// Test different JPEG quality levels
    func testJPEGQualityLevels() throws {
        guard let heicURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }

        // Test low and high quality
        let lowQualityURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: 0.3)
        defer { try? FileManager.default.removeItem(at: lowQualityURL) }

        let highQualityURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: highQualityURL) }

        let lowQualitySize = try Data(contentsOf: lowQualityURL).count
        let highQualitySize = try Data(contentsOf: highQualityURL).count

        // Higher quality should generally produce larger files
        XCTAssertGreaterThan(highQualitySize, lowQualitySize,
                           "Higher quality should produce larger files")
    }

    /// Test error handling with invalid file
    func testConversionWithInvalidFile() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("invalid_\(UUID().uuidString).heic")

        // Write invalid data
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])

        do {
            try invalidData.write(to: tempURL)
            defer { try? FileManager.default.removeItem(at: tempURL) }

            // This should throw an error
            XCTAssertThrowsError(
                try OCROperationsWrapper.convertHEICToJPEG(heicURL: tempURL, quality: 0.95),
                "Should throw error for invalid HEIC file"
            )
        } catch {
            XCTFail("Failed to write test file: \(error)")
        }
    }
}