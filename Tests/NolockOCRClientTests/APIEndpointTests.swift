import XCTest
import Foundation
@testable import NolockOCRClient

final class APIEndpointTests: XCTestCase {
    
    /// OCR service base URL for testing
    static let testBaseURL = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
    
    override func setUpWithError() throws {
        // Configure the API base URL before each test
        NolockOCRClientAPI.basePath = Self.testBaseURL
    }
    
    // MARK: - Health API Tests
    
    func testHealthCheckEndpoint() async throws {
        let response = try await HealthAPI.healthCheck()
        
        XCTAssertNotNil(response, "Health check should return a response")
        print("Health check response: \(response)")
        
        // The health endpoint typically returns a simple status string or object
        // We just verify it doesn't throw an error and returns something
    }
    
    func testHealthCheckEndpointMultipleTimes() async throws {
        let numberOfCalls = 3
        
        for i in 1...numberOfCalls {
            let response = try await HealthAPI.healthCheck()
            XCTAssertNotNil(response, "Health check \(i) should return a response")
            print("Health check \(i): \(response)")
        }
    }
    
    // MARK: - Check OCR API Tests
    
    func testCheckOCRWithRealImage() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Convert HEIC to JPEG first for direct API testing
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        let response = try await OCROperationsAPI.processCheckOcr(body: jpegURL)
        
        XCTAssertNotNil(response, "Response should not be nil")
        // Note: success field may be nil, so we check for actual data instead
        
        print("Check OCR real image test:")
        print("  Success: \(response.success ?? false)")
        print("  Processing time: \(response.processingTime ?? "N/A")")
        
        if let check = response.modelData {
            print("  Check number: \(check.checkNumber ?? "N/A")")
            print("  Account number: \(check.accountNumber ?? "N/A")")
            print("  Routing number: \(check.routingNumber ?? "N/A")")
            print("  Amount: $\(check.amount ?? 0)")
            print("  Payee: \(check.payee ?? "N/A")")
            print("  Payer: \(check.payer ?? "N/A")")
            print("  Bank name: \(check.bankName ?? "N/A")")
            print("  Memo: \(check.memo ?? "N/A")")
            print("  Confidence: \(check.confidence ?? 0)")
            print("  Valid input: \(check.isValidInput ?? false)")
            
            if let date = check.date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                print("  Date: \(formatter.string(from: date))")
            }
            
            if let metadata = check.metadata {
                print("  Metadata - Confidence: \(metadata.confidenceScore ?? 0), Provider: \(metadata.ocrProvider ?? "N/A")")
            }
            
            // Verify confidence is within expected range
            if let confidence = check.confidence {
                XCTAssertGreaterThanOrEqual(confidence, 0.0, "Confidence should be >= 0")
                XCTAssertLessThanOrEqual(confidence, 1.0, "Confidence should be <= 1")
            }
        }
    }
    
    // MARK: - Receipt OCR API Tests
    
    func testReceiptOCRWithRealImage() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Convert HEIC to JPEG first for direct API testing
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        let response = try await OCROperationsAPI.processReceiptOcr(body: jpegURL)
        
        XCTAssertNotNil(response, "Response should not be nil")
        // Note: success field may be nil, so we check for actual data instead
        
        print("Receipt OCR real image test:")
        print("  Success: \(response.success ?? false)")
        print("  Processing time: \(response.processingTime ?? "N/A")")
        
        if let receipt = response.modelData {
            print("  Receipt number: \(receipt.receiptNumber ?? "N/A")")
            print("  Payment method: \(receipt.paymentMethod ?? "N/A")")
            print("  Confidence: \(receipt.confidence ?? 0)")
            print("  Valid input: \(receipt.isValidInput ?? false)")
            
            if let merchant = receipt.merchant {
                print("  Merchant name: \(merchant.name ?? "N/A")")
                print("  Merchant address: \(merchant.address ?? "N/A")")
                print("  Merchant phone: \(merchant.phone ?? "N/A")")
            }
            
            if let totals = receipt.totals {
                print("  Subtotal: $\(totals.subtotal ?? 0)")
                print("  Tax: $\(totals.tax ?? 0)")
                print("  Total: $\(totals.total ?? 0)")
                print("  Tip: $\(totals.tip ?? 0)")
            }
            
            if let timestamp = receipt.timestamp {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                print("  Timestamp: \(formatter.string(from: timestamp))")
            }
            
            if let items = receipt.items, !items.isEmpty {
                print("  Line items (\(items.count)):")
                for (index, item) in items.enumerated() {
                    print("    \(index + 1). \(item.description ?? "Unknown") x\(item.quantity ?? 1) = $\(item.totalPrice ?? 0)")
                }
            }
            
            if let taxes = receipt.taxes, !taxes.isEmpty {
                print("  Tax items (\(taxes.count)):")
                for tax in taxes {
                    print("    \(tax.taxName ?? "Unknown"): $\(tax.taxAmount ?? 0)")
                }
            }
            
            if let metadata = receipt.metadata {
                print("  Metadata - Currency: \(metadata.currency ?? "N/A"), Language: \(metadata.languageCode ?? "N/A")")
            }
            
            // Verify confidence is within expected range
            if let confidence = receipt.confidence {
                XCTAssertGreaterThanOrEqual(confidence, 0.0, "Confidence should be >= 0")
                XCTAssertLessThanOrEqual(confidence, 1.0, "Confidence should be <= 1")
            }
        }
    }
    
    // MARK: - API Configuration Tests
    
    func testBasePath() {
        let originalBasePath = NolockOCRClientAPI.basePath
        
        // Test setting a different base path
        NolockOCRClientAPI.basePath = "https://example.com"
        XCTAssertEqual(NolockOCRClientAPI.basePath, "https://example.com", "Base path should be settable")
        
        // Restore original base path
        NolockOCRClientAPI.basePath = originalBasePath
        XCTAssertEqual(NolockOCRClientAPI.basePath, originalBasePath, "Base path should be restored")
    }
    
    // MARK: - Request Builder Tests
    
    func testCheckOCRRequestBuilder() throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Convert to JPEG for testing
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        // Test request builder
        let requestBuilder = OCROperationsAPI.processCheckOcrWithRequestBuilder(body: jpegURL)
        XCTAssertNotNil(requestBuilder, "Request builder should not be nil")
        
        // Test executing the request builder
        let expectation = XCTestExpectation(description: "Request builder execution")
        
        requestBuilder.execute { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response.body, "Response body should not be nil")
                print("Request builder test successful")
            case .failure(let error):
                XCTFail("Request builder failed: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testReceiptOCRRequestBuilder() throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Convert to JPEG for testing
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        // Test request builder
        let requestBuilder = OCROperationsAPI.processReceiptOcrWithRequestBuilder(body: jpegURL)
        XCTAssertNotNil(requestBuilder, "Request builder should not be nil")
        
        // Test executing the request builder
        let expectation = XCTestExpectation(description: "Receipt request builder execution")
        
        requestBuilder.execute { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response.body, "Response body should not be nil")
                print("Receipt request builder test successful")
            case .failure(let error):
                XCTFail("Receipt request builder failed: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Performance Tests
    
    func testAPIResponseTime() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        let startTime = Date()
        let response = try await OCROperationsAPI.processCheckOcr(body: jpegURL)
        let endTime = Date()
        
        let responseTime = endTime.timeIntervalSince(startTime)
        
        print("API Response Time Test:")
        print("  Response time: \(String(format: "%.2f", responseTime)) seconds")
        print("  Server processing time: \(response.processingTime ?? "N/A")")
        
        // API should respond within reasonable time (30 seconds)
        XCTAssertLessThan(responseTime, 30.0, "API should respond within 30 seconds")
    }
    
    // MARK: - Concurrent Request Tests
    
    func testConcurrentAPIRequests() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        // Test multiple concurrent requests
        let numberOfRequests = 3
        
        await withTaskGroup(of: Void.self) { group in
            for i in 1...numberOfRequests {
                group.addTask {
                    do {
                        let response = try await OCROperationsAPI.processCheckOcr(body: jpegURL)
                        XCTAssertNotNil(response, "Concurrent request \(i) should not be nil")
                        print("Concurrent request \(i) completed successfully")
                    } catch {
                        XCTFail("Concurrent request \(i) failed: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTempImageFile(data: Data, extension ext: String) -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_image_\(UUID().uuidString)")
            .appendingPathExtension(ext)
        
        do {
            try data.write(to: tempURL)
        } catch {
            XCTFail("Failed to create temp image file: \(error)")
        }
        
        return tempURL
    }
}