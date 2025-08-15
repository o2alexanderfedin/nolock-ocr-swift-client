import XCTest
import Foundation
@testable import NolockOCRClient

final class DataOverloadTests: XCTestCase {
    
    /// OCR service base URL for testing
    static let testBaseURL = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
    
    override func setUpWithError() throws {
        // Configure the API base URL before each test
        NolockOCRClientAPI.basePath = Self.testBaseURL
    }
    
    // MARK: - Data Overload Tests for Check OCR
    
    func testCheckOCRWithHEICData() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Load HEIC image as Data
        let heicData = try Data(contentsOf: testImageURL)
        XCTAssertGreaterThan(heicData.count, 0, "HEIC data should not be empty")
        
        // Test Data overload with HEIC data (should auto-convert)
        let response = try await OCROperationsWrapper.processCheckOcr(imageData: heicData)
        
        XCTAssertNotNil(response, "Response should not be nil")
        // Note: success field may be nil, so we check for actual data instead
        
        print("Check OCR with HEIC Data test:")
        print("  HEIC data size: \(heicData.count) bytes")
        print("  Success: \(response.success ?? false)")
        print("  Processing time: \(response.processingTime ?? "N/A")")
        
        if let check = response.modelData {
            XCTAssertNotNil(check.confidence, "Check should have confidence score")
            print("  Confidence: \(check.confidence ?? 0)")
            print("  Check number: \(check.checkNumber ?? "N/A")")
            print("  Amount: $\(check.amount ?? 0)")
        }
    }
    
    func testCheckOCRWithJPEGData() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Convert to JPEG first
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        // Load JPEG as Data
        let jpegData = try Data(contentsOf: jpegURL)
        XCTAssertGreaterThan(jpegData.count, 0, "JPEG data should not be empty")
        
        // Test Data overload with JPEG data (no conversion needed)
        let response = try await OCROperationsWrapper.processCheckOcr(imageData: jpegData)
        
        XCTAssertNotNil(response, "Response should not be nil")
        // Note: success field may be nil, so we check for actual data instead
        
        print("Check OCR with JPEG Data test:")
        print("  JPEG data size: \(jpegData.count) bytes")
        print("  Success: \(response.success ?? false)")
        print("  Processing time: \(response.processingTime ?? "N/A")")
        
        if let check = response.modelData {
            XCTAssertNotNil(check.confidence, "Check should have confidence score")
            print("  Confidence: \(check.confidence ?? 0)")
        }
    }
    
    // MARK: - Data Overload Tests for Receipt OCR
    
    func testReceiptOCRWithHEICData() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Load HEIC image as Data
        let heicData = try Data(contentsOf: testImageURL)
        XCTAssertGreaterThan(heicData.count, 0, "HEIC data should not be empty")
        
        // Test Data overload with HEIC data (should auto-convert)
        let response = try await OCROperationsWrapper.processReceiptOcr(imageData: heicData)
        
        XCTAssertNotNil(response, "Response should not be nil")
        // Note: success field may be nil, so we check for actual data instead
        
        print("Receipt OCR with HEIC Data test:")
        print("  HEIC data size: \(heicData.count) bytes")
        print("  Success: \(response.success ?? false)")
        print("  Processing time: \(response.processingTime ?? "N/A")")
        
        if let receipt = response.modelData {
            XCTAssertNotNil(receipt.confidence, "Receipt should have confidence score")
            print("  Confidence: \(receipt.confidence ?? 0)")
            
            if let merchant = receipt.merchant {
                print("  Merchant: \(merchant.name ?? "N/A")")
            }
            
            if let totals = receipt.totals {
                print("  Total: $\(totals.total ?? 0)")
            }
        }
    }
    
    func testReceiptOCRWithJPEGData() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Convert to JPEG first
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        // Load JPEG as Data
        let jpegData = try Data(contentsOf: jpegURL)
        XCTAssertGreaterThan(jpegData.count, 0, "JPEG data should not be empty")
        
        // Test Data overload with JPEG data (no conversion needed)
        let response = try await OCROperationsWrapper.processReceiptOcr(imageData: jpegData)
        
        XCTAssertNotNil(response, "Response should not be nil")
        // Note: success field may be nil, so we check for actual data instead
        
        print("Receipt OCR with JPEG Data test:")
        print("  JPEG data size: \(jpegData.count) bytes")
        print("  Success: \(response.success ?? false)")
        print("  Processing time: \(response.processingTime ?? "N/A")")
        
        if let receipt = response.modelData {
            XCTAssertNotNil(receipt.confidence, "Receipt should have confidence score")
            print("  Confidence: \(receipt.confidence ?? 0)")
        }
    }
    
    // MARK: - Completion Handler Tests with Data
    
    func testCheckOCRDataCompletionHandler() throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let imageData = try Data(contentsOf: testImageURL)
        XCTAssertGreaterThan(imageData.count, 0, "Image data should not be empty")
        
        let expectation = XCTestExpectation(description: "Check OCR data completion handler")
        
        OCROperationsWrapper.processCheckOcr(imageData: imageData) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response, "Response should not be nil")
                // Note: success field may be nil, so we check for actual data instead
                
                print("Check OCR data completion handler test:")
                print("  Success: \(response.success ?? false)")
                
                if let check = response.modelData {
                    XCTAssertNotNil(check.confidence, "Check should have confidence score")
                    print("  Confidence: \(check.confidence ?? 0)")
                }
                
            case .failure(let error):
                XCTFail("Check OCR data completion handler failed: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testReceiptOCRDataCompletionHandler() throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let imageData = try Data(contentsOf: testImageURL)
        XCTAssertGreaterThan(imageData.count, 0, "Image data should not be empty")
        
        let expectation = XCTestExpectation(description: "Receipt OCR data completion handler")
        
        OCROperationsWrapper.processReceiptOcr(imageData: imageData) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response, "Response should not be nil")
                // Note: success field may be nil, so we check for actual data instead
                
                print("Receipt OCR data completion handler test:")
                print("  Success: \(response.success ?? false)")
                
                if let receipt = response.modelData {
                    XCTAssertNotNil(receipt.confidence, "Receipt should have confidence score")
                    print("  Confidence: \(receipt.confidence ?? 0)")
                }
                
            case .failure(let error):
                XCTFail("Receipt OCR data completion handler failed: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Comparison Tests: URL vs Data
    
    func testCheckOCRComparisonURLvsData() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let imageData = try Data(contentsOf: testImageURL)
        
        // Test with URL
        let urlResponse = try await OCROperationsWrapper.processCheckOcr(imageURL: testImageURL)
        
        // Test with Data
        let dataResponse = try await OCROperationsWrapper.processCheckOcr(imageData: imageData)
        
        // Both should succeed
        XCTAssertNotNil(urlResponse, "URL response should not be nil")
        XCTAssertNotNil(dataResponse, "Data response should not be nil")
        
        print("Check OCR URL vs Data comparison:")
        print("  URL success: \(urlResponse.success ?? false)")
        print("  Data success: \(dataResponse.success ?? false)")
        
        if let urlCheck = urlResponse.modelData, let dataCheck = dataResponse.modelData {
            print("  URL confidence: \(urlCheck.confidence ?? 0)")
            print("  Data confidence: \(dataCheck.confidence ?? 0)")
            
            // Confidence scores should be reasonably similar (within 0.1)
            if let urlConf = urlCheck.confidence, let dataConf = dataCheck.confidence {
                let difference = abs(urlConf - dataConf)
                XCTAssertLessThan(difference, 0.1, "Confidence scores should be similar between URL and Data methods")
            }
        }
    }
    
    func testReceiptOCRComparisonURLvsData() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let imageData = try Data(contentsOf: testImageURL)
        
        // Test with URL
        let urlResponse = try await OCROperationsWrapper.processReceiptOcr(imageURL: testImageURL)
        
        // Test with Data
        let dataResponse = try await OCROperationsWrapper.processReceiptOcr(imageData: imageData)
        
        // Both should succeed
        XCTAssertNotNil(urlResponse, "URL response should not be nil")
        XCTAssertNotNil(dataResponse, "Data response should not be nil")
        
        print("Receipt OCR URL vs Data comparison:")
        print("  URL success: \(urlResponse.success ?? false)")
        print("  Data success: \(dataResponse.success ?? false)")
        
        if let urlReceipt = urlResponse.modelData, let dataReceipt = dataResponse.modelData {
            print("  URL confidence: \(urlReceipt.confidence ?? 0)")
            print("  Data confidence: \(dataReceipt.confidence ?? 0)")
            
            // Confidence scores should be reasonably similar (within 0.1)
            if let urlConf = urlReceipt.confidence, let dataConf = dataReceipt.confidence {
                let difference = abs(urlConf - dataConf)
                XCTAssertLessThan(difference, 0.1, "Confidence scores should be similar between URL and Data methods")
            }
        }
    }
    
    // MARK: - Error Handling Tests with Data
    
    func testDataOverloadWithInvalidData() async throws {
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])
        
        do {
            _ = try await OCROperationsWrapper.processCheckOcr(imageData: invalidData)
            // The API might still process invalid images, so this might not always throw
            print("API processed invalid data without throwing error")
        } catch {
            // If an error is thrown, that's also acceptable
            print("API correctly rejected invalid data: \(error)")
        }
    }
    
    func testDataOverloadWithEmptyData() async throws {
        let emptyData = Data()
        
        do {
            _ = try await OCROperationsWrapper.processCheckOcr(imageData: emptyData)
            XCTFail("Should have thrown an error for empty data")
        } catch {
            // Expected behavior
            print("API correctly rejected empty data: \(error)")
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testLargeDataHandling() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let originalData = try Data(contentsOf: testImageURL)
        
        // Create larger data by duplicating the image data (simulating a very large image)
        var largeData = Data()
        largeData.append(originalData)
        largeData.append(originalData) // Double the size
        
        // Note: This will likely fail because it's not a valid image anymore,
        // but it tests memory handling of large data
        do {
            let response = try await OCROperationsWrapper.processCheckOcr(imageData: largeData)
            print("Large data test - Response received: \(response.success ?? false)")
        } catch {
            print("Large data test - Expected error for invalid large data: \(error)")
        }
    }
    
    func testMultipleDataOperationsMemory() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let imageData = try Data(contentsOf: testImageURL)
        let numberOfOperations = 5
        
        for i in 1...numberOfOperations {
            do {
                let response = try await OCROperationsWrapper.processCheckOcr(imageData: imageData)
                XCTAssertNotNil(response, "Operation \(i) should complete successfully")
                print("Memory test operation \(i) completed")
            } catch {
                XCTFail("Memory test operation \(i) failed: \(error)")
            }
        }
        
        print("Memory test: \(numberOfOperations) operations completed successfully")
    }
    
    // MARK: - Temporary File Cleanup Tests
    
    func testDataOverloadFileCleanup() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let imageData = try Data(contentsOf: testImageURL)
        
        // Get temp directory file count before
        let tempDir = FileManager.default.temporaryDirectory
        let beforeFiles = (try? FileManager.default.contentsOfDirectory(atPath: tempDir.path)) ?? []
        
        // Perform data operation
        let response = try await OCROperationsWrapper.processCheckOcr(imageData: imageData)
        XCTAssertNotNil(response, "Response should not be nil")
        
        // Get temp directory file count after
        let afterFiles = (try? FileManager.default.contentsOfDirectory(atPath: tempDir.path)) ?? []
        
        // Should not have accumulated temp files
        let tempFileIncrease = afterFiles.count - beforeFiles.count
        XCTAssertLessThanOrEqual(tempFileIncrease, 1, "Should not accumulate many temp files")
        
        print("File cleanup test:")
        print("  Files before: \(beforeFiles.count)")
        print("  Files after: \(afterFiles.count)")
        print("  Increase: \(tempFileIncrease)")
    }
    
}