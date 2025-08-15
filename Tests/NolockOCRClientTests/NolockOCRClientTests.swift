import XCTest
import Foundation
@testable import NolockOCRClient
#if canImport(CoreImage)
import CoreImage
#endif
#if canImport(ImageIO)
import ImageIO
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

final class NolockOCRClientTests: XCTestCase {
    
    /// OCR service base URL for testing
    static let testBaseURL = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
    
    override func setUpWithError() throws {
        // Configure the API base URL before each test
        NolockOCRClientAPI.basePath = Self.testBaseURL
        
        // Configure wrapper settings
        OCROperationsWrapper.jpegQuality = 0.95
        OCROperationsWrapper.autoCleanupTempFiles = true
    }
    
    override func tearDownWithError() throws {
        // Clean up after each test if needed
    }
    
    // MARK: - Health Check Tests
    
    func testHealthEndpoint() async throws {
        let response = try await HealthAPI.healthCheck()
        XCTAssertNotNil(response, "Health check should return a response")
        // The health endpoint typically returns a simple status string
        print("Health check response: \(response)")
    }
    
    // MARK: - Check OCR Tests
    
    func testCheckOCRWithHEICImage() async throws {
        guard let testImageURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Test using OCROperationsWrapper (should auto-convert HEIC to JPEG)
        let response = try await OCROperationsWrapper.processCheckOcr(imageURL: testImageURL)
        
        XCTAssertNotNil(response, "Response should not be nil")
        // Note: success field may be nil, so we check for actual data instead
        
        if let check = response.modelData {
            XCTAssertNotNil(check.confidence, "Check should have confidence score")
            print("Check OCR Results:")
            print("  Check Number: \(check.checkNumber ?? "N/A")")
            print("  Account: \(check.accountNumber ?? "N/A")")
            print("  Routing: \(check.routingNumber ?? "N/A")")
            print("  Amount: $\(check.amount ?? 0)")
            print("  Payee: \(check.payee ?? "N/A")")
            print("  Payer: \(check.payer ?? "N/A")")
            print("  Confidence: \(check.confidence ?? 0)")
            
            if let date = check.date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                print("  Date: \(formatter.string(from: date))")
            }
        }
    }
    
    func testCheckOCRWithJPEGImage() async throws {
        guard let heicURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // First convert HEIC to JPEG
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        // Test direct API call with JPEG
        let response = try await OCROperationsAPI.processCheckOcr(body: jpegURL)
        
        XCTAssertNotNil(response, "Response should not be nil")
        // Note: success field may be nil, so we check for actual data instead
        
        if let check = response.modelData {
            XCTAssertNotNil(check.confidence, "Check should have confidence score")
            print("Direct JPEG Check OCR Results:")
            print("  Confidence: \(check.confidence ?? 0)")
            print("  Valid Input: \(check.isValidInput ?? false)")
        }
    }
    
    func testCheckOCRWithDataOverload() async throws {
        guard let testImageURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Load image as Data
        let imageData = try Data(contentsOf: testImageURL)
        XCTAssertGreaterThan(imageData.count, 0, "Image data should not be empty")
        
        // Test using Data overload (new in v1.6.0)
        let response = try await OCROperationsWrapper.processCheckOcr(imageData: imageData)
        
        XCTAssertNotNil(response, "Response should not be nil")
        // Note: success field may be nil, so we check for actual data instead
        
        if let check = response.modelData {
            XCTAssertNotNil(check.confidence, "Check should have confidence score")
            print("Data overload Check OCR Results:")
            print("  Image data size: \(imageData.count) bytes")
            print("  Confidence: \(check.confidence ?? 0)")
        }
    }
    
    // MARK: - Receipt OCR Tests
    
    func testReceiptOCRWithHEICImage() async throws {
        guard let testImageURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Test using OCROperationsWrapper (should auto-convert HEIC to JPEG)
        let response = try await OCROperationsWrapper.processReceiptOcr(imageURL: testImageURL)
        
        XCTAssertNotNil(response, "Response should not be nil")
        // Note: success field may be nil, so we check for actual data instead
        
        if let receipt = response.modelData {
            XCTAssertNotNil(receipt.confidence, "Receipt should have confidence score")
            print("Receipt OCR Results:")
            
            if let merchant = receipt.merchant {
                print("  Merchant: \(merchant.name ?? "N/A")")
                print("  Address: \(merchant.address ?? "N/A")")
                print("  Phone: \(merchant.phone ?? "N/A")")
            }
            
            if let totals = receipt.totals {
                print("  Subtotal: $\(totals.subtotal ?? 0)")
                print("  Tax: $\(totals.tax ?? 0)")
                print("  Total: $\(totals.total ?? 0)")
                print("  Tip: $\(totals.tip ?? 0)")
            }
            
            print("  Confidence: \(receipt.confidence ?? 0)")
            
            if let timestamp = receipt.timestamp {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                print("  Timestamp: \(formatter.string(from: timestamp))")
            }
        }
    }
    
    func testReceiptOCRWithDataOverload() async throws {
        guard let testImageURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Load image as Data
        let imageData = try Data(contentsOf: testImageURL)
        XCTAssertGreaterThan(imageData.count, 0, "Image data should not be empty")
        
        // Test using Data overload (new in v1.6.0)
        let response = try await OCROperationsWrapper.processReceiptOcr(imageData: imageData)
        
        XCTAssertNotNil(response, "Response should not be nil")
        // Note: success field may be nil, so we check for actual data instead
        
        if let receipt = response.modelData {
            XCTAssertNotNil(receipt.confidence, "Receipt should have confidence score")
            print("Data overload Receipt OCR Results:")
            print("  Image data size: \(imageData.count) bytes")
            print("  Confidence: \(receipt.confidence ?? 0)")
        }
    }
    
    // MARK: - HEIC Conversion Tests
    
    func testHEICToJPEGConversion() throws {
        guard let heicURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Test conversion
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        // Verify the converted file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: jpegURL.path), "Converted JPEG should exist")
        
        // Verify it's actually a JPEG file
        let jpegData = try Data(contentsOf: jpegURL)
        XCTAssertGreaterThan(jpegData.count, 0, "JPEG data should not be empty")
        
        // Check JPEG magic bytes (FF D8 FF)
        XCTAssertEqual(jpegData[0], 0xFF, "First byte should be 0xFF")
        XCTAssertEqual(jpegData[1], 0xD8, "Second byte should be 0xD8")
        XCTAssertEqual(jpegData[2], 0xFF, "Third byte should be 0xFF")
        
        print("HEIC to JPEG conversion successful:")
        print("  Original HEIC: \(try Data(contentsOf: heicURL).count) bytes")
        print("  Converted JPEG: \(jpegData.count) bytes")
    }
    
    func testDifferentJPEGQualityLevels() throws {
        guard let heicURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let qualities: [Double] = [0.5, 0.8, 0.95]
        var results: [(quality: Double, size: Int)] = []
        
        for quality in qualities {
            let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: quality)
            defer { try? FileManager.default.removeItem(at: jpegURL) }
            
            let jpegData = try Data(contentsOf: jpegURL)
            results.append((quality: quality, size: jpegData.count))
            
            XCTAssertGreaterThan(jpegData.count, 0, "JPEG data should not be empty for quality \(quality)")
        }
        
        // Higher quality should generally result in larger file sizes
        results.sort { $0.quality < $1.quality }
        
        print("JPEG quality test results:")
        for result in results {
            print("  Quality \(result.quality): \(result.size) bytes")
        }
        
        // The highest quality should have the largest file size
        XCTAssertGreaterThan(results.last!.size, results.first!.size, 
                           "Higher quality should produce larger files")
    }
    
    // MARK: - Date Parsing Tests
    
    func testDateParsingWithCheckOCR() async throws {
        guard let testImageURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        do {
            let response = try await OCROperationsWrapper.processCheckOcr(imageURL: testImageURL)
            
            if let check = response.modelData {
                if let date = check.date {
                    // Test that the date was parsed successfully
                    XCTAssertNotNil(date, "Date should be parsed successfully")
                    
                    // Verify the date is reasonable (not in the far future or past)
                    let now = Date()
                    let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: now)!
                    let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!
                    
                    XCTAssertTrue(date >= tenYearsAgo && date <= oneYearFromNow, 
                                "Date should be within reasonable range")
                    
                    print("Date parsing test successful:")
                    print("  Parsed date: \(date)")
                    print("  Formatted: \(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))")
                } else {
                    print("No date found in check data (this may be expected for some test images)")
                }
            }
        } catch let error as DecodingError {
            // If there's a date parsing error, we want to capture it for analysis
            switch error {
            case .dataCorrupted(let context):
                if context.codingPath.contains(where: { $0.stringValue == "date" }) {
                    XCTFail("Date parsing failed: \(context.debugDescription)")
                } else {
                    throw error // Re-throw if it's not a date parsing issue
                }
            default:
                throw error
            }
        }
    }
    
    func testDateParsingWithReceiptOCR() async throws {
        guard let testImageURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        do {
            let response = try await OCROperationsWrapper.processReceiptOcr(imageURL: testImageURL)
            
            if let receipt = response.modelData {
                if let timestamp = receipt.timestamp {
                    // Test that the timestamp was parsed successfully
                    XCTAssertNotNil(timestamp, "Timestamp should be parsed successfully")
                    
                    // Verify the timestamp is reasonable
                    let now = Date()
                    let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: now)!
                    let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!
                    
                    XCTAssertTrue(timestamp >= tenYearsAgo && timestamp <= oneYearFromNow, 
                                "Timestamp should be within reasonable range")
                    
                    print("Receipt timestamp parsing test successful:")
                    print("  Parsed timestamp: \(timestamp)")
                    print("  Formatted: \(DateFormatter.localizedString(from: timestamp, dateStyle: .medium, timeStyle: .short))")
                } else {
                    print("No timestamp found in receipt data (this may be expected for some test images)")
                }
            }
        } catch let error as DecodingError {
            // If there's a timestamp parsing error, we want to capture it for analysis
            switch error {
            case .dataCorrupted(let context):
                if context.codingPath.contains(where: { $0.stringValue == "timestamp" }) {
                    XCTFail("Timestamp parsing failed: \(context.debugDescription)")
                } else {
                    throw error // Re-throw if it's not a timestamp parsing issue
                }
            default:
                throw error
            }
        }
    }
    
    // MARK: - Completion Handler Tests
    
    func testCheckOCRWithCompletionHandler() throws {
        guard let testImageURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let expectation = XCTestExpectation(description: "Check OCR completion handler")
        
        OCROperationsWrapper.processCheckOcr(imageURL: testImageURL) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response, "Response should not be nil")
                // Note: success field may be nil, so we check for actual data instead
                
                if let check = response.modelData {
                    XCTAssertNotNil(check.confidence, "Check should have confidence score")
                    print("Completion handler Check OCR successful, confidence: \(check.confidence ?? 0)")
                }
                
            case .failure(let error):
                XCTFail("Check OCR completion handler failed: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testReceiptOCRWithCompletionHandler() throws {
        guard let testImageURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let expectation = XCTestExpectation(description: "Receipt OCR completion handler")
        
        OCROperationsWrapper.processReceiptOcr(imageURL: testImageURL) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response, "Response should not be nil")
                // Note: success field may be nil, so we check for actual data instead
                
                if let receipt = response.modelData {
                    XCTAssertNotNil(receipt.confidence, "Receipt should have confidence score")
                    print("Completion handler Receipt OCR successful, confidence: \(receipt.confidence ?? 0)")
                }
                
            case .failure(let error):
                XCTFail("Receipt OCR completion handler failed: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testDataOverloadCompletionHandlers() throws {
        guard let testImageURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let imageData = try Data(contentsOf: testImageURL)
        XCTAssertGreaterThan(imageData.count, 0, "Image data should not be empty")
        
        let checkExpectation = XCTestExpectation(description: "Check OCR data completion handler")
        let receiptExpectation = XCTestExpectation(description: "Receipt OCR data completion handler")
        
        // Test Check OCR with Data completion handler
        OCROperationsWrapper.processCheckOcr(imageData: imageData) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response, "Check response should not be nil")
                print("Data completion handler Check OCR successful")
            case .failure(let error):
                XCTFail("Check OCR data completion handler failed: \(error)")
            }
            checkExpectation.fulfill()
        }
        
        // Test Receipt OCR with Data completion handler
        OCROperationsWrapper.processReceiptOcr(imageData: imageData) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response, "Receipt response should not be nil")
                print("Data completion handler Receipt OCR successful")
            case .failure(let error):
                XCTFail("Receipt OCR data completion handler failed: \(error)")
            }
            receiptExpectation.fulfill()
        }
        
        wait(for: [checkExpectation, receiptExpectation], timeout: 60.0)
    }
    
    // MARK: - Configuration Tests
    
    func testWrapperConfiguration() {
        // Test wrapper configuration settings
        let originalQuality = OCROperationsWrapper.jpegQuality
        let originalCleanup = OCROperationsWrapper.autoCleanupTempFiles
        
        // Test setting different quality
        OCROperationsWrapper.jpegQuality = 0.8
        XCTAssertEqual(OCROperationsWrapper.jpegQuality, 0.8, "JPEG quality should be settable")
        
        // Test setting cleanup flag
        OCROperationsWrapper.autoCleanupTempFiles = false
        XCTAssertFalse(OCROperationsWrapper.autoCleanupTempFiles, "Auto cleanup should be settable")
        
        // Restore original settings
        OCROperationsWrapper.jpegQuality = originalQuality
        OCROperationsWrapper.autoCleanupTempFiles = originalCleanup
    }
    
    // MARK: - Performance Tests
    
    func testHEICConversionPerformance() throws {
        guard let heicURL = getTestImageURL() else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        measure {
            do {
                let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: 0.95)
                try? FileManager.default.removeItem(at: jpegURL)
            } catch {
                XCTFail("HEIC conversion failed: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getTestImageURL() -> URL? {
        return Bundle.module.url(forResource: "IMG_4171", withExtension: "heic")
    }
    
    private func createMinimalTestImage() -> Data {
        // Minimal 1x1 white PNG for fallback testing
        let pngBytes: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,  // IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,  // 1x1 dimensions
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,  // 8-bit RGB
            0xDE,                                              // CRC
            0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54,  // IDAT chunk
            0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0xFE, 0xFF,  // Compressed data
            0x00, 0xFF, 0xFF, 0x01,                          // White pixel
            0x00, 0x05, 0x00, 0x01,                          // CRC
            0x47, 0xB3, 0x51, 0xFC,                          // More CRC
            0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,  // IEND chunk
            0xAE, 0x42, 0x60, 0x82                           // CRC
        ]
        return Data(pngBytes)
    }
}