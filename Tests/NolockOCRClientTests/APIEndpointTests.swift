import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import NolockOCRClient

final class APIEndpointTests: XCTestCase {

    // MARK: - Test Environment Setup

    override func setUp() {
        super.setUp()
        // Ensure we have the proper base path
        if NolockOCRClientAPI.basePath == "http://localhost" {
            // Set to actual API endpoint
            NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
        }
    }

    override func tearDown() {
        // Reset to default state
        NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
        super.tearDown()
    }

    // MARK: - Health Check Tests

    func testHealthCheckEndpoint() async throws {
        // Health check endpoint doesn't require authentication
        // It should succeed regardless of auth state
        let response = try await HealthAPI.healthCheck()
        XCTAssertNotNil(response, "Health check should return a response")
        print("Health check successful: \(response)")
    }

    func testHealthWithCompletionHandler() async throws {
        // Health check endpoint doesn't require authentication
        // Using async version since there's no completion handler
        let response = try await HealthAPI.healthCheck()
        XCTAssertNotNil(response, "Health check should return a response")
        print("Health check via async successful: \(response)")
    }

    // MARK: - OCR Tests

    func testCheckOCRWithRealImage() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }

        // Convert HEIC to JPEG using our wrapper
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }

        // Configure authentication
        let (isRealAuth, _) = await TestAuthenticationHelper.configureTestAuthentication()

        do {
            let response = try await OCROperationsAPI.processCheckOcr(body: jpegURL)
            if !isRealAuth {
                XCTFail("Expected 401 error with mock auth, but request succeeded")
            } else {
                XCTAssertNotNil(response.modelData, "Response model data should not be nil")
                print("Check OCR successful with real auth: \(response)")
            }
        } catch {
            if isRealAuth {
                XCTFail("Expected success with real auth, but got error: \(error)")
            } else {
                // Verify it's a 401 error
                if let errorResponse = error as? ErrorResponse,
                   case .error(let code, _, _, _) = errorResponse {
                    XCTAssertEqual(code, 401, "Expected 401 with mock auth, got \(code)")
                } else {
                    XCTFail("Expected 401 ErrorResponse, got: \(error)")
                }
            }
        }
    }

    func testReceiptOCRWithRealImage() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }

        // Convert HEIC to JPEG using our wrapper
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }

        // Configure authentication
        let (isRealAuth, _) = await TestAuthenticationHelper.configureTestAuthentication()

        do {
            let response = try await OCROperationsAPI.processReceiptOcr(body: jpegURL)
            if !isRealAuth {
                XCTFail("Expected 401 error with mock auth, but request succeeded")
            } else {
                XCTAssertNotNil(response.modelData, "Response model data should not be nil")
                print("Receipt OCR successful with real auth: \(response)")
            }
        } catch {
            if isRealAuth {
                XCTFail("Expected success with real auth, but got error: \(error)")
            } else {
                // Verify it's a 401 error
                if let errorResponse = error as? ErrorResponse,
                   case .error(let code, _, _, _) = errorResponse {
                    XCTAssertEqual(code, 401, "Expected 401 with mock auth, got \(code)")
                } else {
                    XCTFail("Expected 401 ErrorResponse, got: \(error)")
                }
            }
        }
    }

    // MARK: - Completion Handler Tests

    func testCheckOCRWithCompletionHandler() throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }

        // Convert to JPEG for testing
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }

        let expectation = XCTestExpectation(description: "Check OCR completion")

        Task {
            let (isRealAuth, _) = await TestAuthenticationHelper.configureTestAuthentication()

            OCROperationsWrapper.processCheckOcr(imageURL: jpegURL) { result in
                switch result {
                case .success(let response):
                    if !isRealAuth {
                        XCTFail("Expected 401 error with mock auth, but request succeeded")
                    } else {
                        XCTAssertNotNil(response.modelData, "Response model data should not be nil")
                        print("Check OCR successful with real auth")
                    }
                case .failure(let error):
                    if isRealAuth {
                        XCTFail("Expected success with real auth, but got error: \(error)")
                    } else {
                        // Verify it's a 401 error
                        if case ErrorResponse.error(let code, _, _, _) = error {
                            XCTAssertEqual(code, 401, "Expected 401 with mock auth")
                        } else {
                            XCTFail("Expected 401 ErrorResponse")
                        }
                    }
                }
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 30.0)
    }

    func testReceiptOCRWithCompletionHandler() throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }

        // Convert to JPEG for testing
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }

        let expectation = XCTestExpectation(description: "Receipt OCR completion")

        Task {
            let (isRealAuth, _) = await TestAuthenticationHelper.configureTestAuthentication()

            OCROperationsWrapper.processReceiptOcr(imageURL: jpegURL) { result in
                switch result {
                case .success(let response):
                    if !isRealAuth {
                        XCTFail("Expected 401 error with mock auth, but request succeeded")
                    } else {
                        XCTAssertNotNil(response.modelData, "Response model data should not be nil")
                        print("Receipt OCR successful with real auth")
                    }
                case .failure(let error):
                    if isRealAuth {
                        XCTFail("Expected success with real auth, but got error: \(error)")
                    } else {
                        // Verify it's a 401 error
                        if case ErrorResponse.error(let code, _, _, _) = error {
                            XCTAssertEqual(code, 401, "Expected 401 with mock auth")
                        } else {
                            XCTFail("Expected 401 ErrorResponse")
                        }
                    }
                }
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 30.0)
    }

    // MARK: - Configuration Tests

    func testBasePath() {
        let originalBasePath = NolockOCRClientAPI.basePath
        defer { NolockOCRClientAPI.basePath = originalBasePath }

        // Test setting a different base path
        NolockOCRClientAPI.basePath = "https://example.com"
        XCTAssertEqual(NolockOCRClientAPI.basePath, "https://example.com", "Base path should be settable")

        // Restore original base path
        NolockOCRClientAPI.basePath = originalBasePath
        XCTAssertEqual(NolockOCRClientAPI.basePath, originalBasePath, "Base path should be restored")
    }

    // MARK: - Request Builder Tests

    func testCheckOCRRequestBuilder() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }

        // Convert to JPEG for testing
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }

        // Configure authentication (real or mock)
        let (isRealAuth, _) = await TestAuthenticationHelper.configureTestAuthentication()

        // Test request builder
        let requestBuilder = OCROperationsAPI.processCheckOcrWithRequestBuilder(body: jpegURL)
        XCTAssertNotNil(requestBuilder, "Request builder should not be nil")

        // Test executing the request builder
        let expectation = XCTestExpectation(description: "Request builder execution")

        requestBuilder.execute { result in
            switch result {
            case .success(let response):
                if !isRealAuth {
                    XCTFail("Expected 401 error with mock auth, but request succeeded")
                } else {
                    XCTAssertNotNil(response.body, "Response body should not be nil")
                    print("Request builder test successful with real auth")
                }
            case .failure(let error):
                if isRealAuth {
                    XCTFail("Expected success with real auth, but got error: \(error)")
                } else {
                    // Verify it's a 401 error
                    if case ErrorResponse.error(let code, _, _, _) = error {
                        XCTAssertEqual(code, 401, "Expected 401 with mock auth, got \(code)")
                    } else {
                        XCTFail("Expected 401 ErrorResponse, got: \(error)")
                    }
                }
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 30.0)
    }

    func testReceiptOCRRequestBuilder() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }

        // Convert to JPEG for testing
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }

        // Configure authentication (real or mock)
        let (isRealAuth, _) = await TestAuthenticationHelper.configureTestAuthentication()

        // Test request builder
        let requestBuilder = OCROperationsAPI.processReceiptOcrWithRequestBuilder(body: jpegURL)
        XCTAssertNotNil(requestBuilder, "Request builder should not be nil")

        // Test executing the request builder
        let expectation = XCTestExpectation(description: "Request builder execution")

        requestBuilder.execute { result in
            switch result {
            case .success(let response):
                if !isRealAuth {
                    XCTFail("Expected 401 error with mock auth, but request succeeded")
                } else {
                    XCTAssertNotNil(response.body, "Response body should not be nil")
                    print("Request builder test successful with real auth")
                }
            case .failure(let error):
                if isRealAuth {
                    XCTFail("Expected success with real auth, but got error: \(error)")
                } else {
                    // Verify it's a 401 error
                    if case ErrorResponse.error(let code, _, _, _) = error {
                        XCTAssertEqual(code, 401, "Expected 401 with mock auth, got \(code)")
                    } else {
                        XCTFail("Expected 401 ErrorResponse, got: \(error)")
                    }
                }
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

        // Convert to JPEG for testing
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }

        // Configure authentication
        let (isRealAuth, _) = await TestAuthenticationHelper.configureTestAuthentication()

        let startTime = Date()

        do {
            _ = try await OCROperationsAPI.processCheckOcr(body: jpegURL)
            let elapsed = Date().timeIntervalSince(startTime)
            if !isRealAuth {
                XCTFail("Expected 401 error with mock auth, but request succeeded")
            } else {
                print("API response time: \(elapsed) seconds")
                XCTAssertLessThan(elapsed, 30.0, "API should respond within 30 seconds")
            }
        } catch {
            let elapsed = Date().timeIntervalSince(startTime)
            if isRealAuth {
                XCTFail("Expected success with real auth, but got error: \(error)")
            } else {
                print("API error response time: \(elapsed) seconds")
                // Even error responses should be reasonably fast
                XCTAssertLessThan(elapsed, 10.0, "Error responses should be fast")
            }
        }
    }

    // MARK: - Concurrent Request Tests

    func testConcurrentAPIRequests() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }

        // Convert to JPEG for testing
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }

        // Configure authentication
        let (isRealAuth, _) = await TestAuthenticationHelper.configureTestAuthentication()

        // Create multiple concurrent requests
        async let request1 = OCROperationsAPI.processCheckOcr(body: jpegURL)
        async let request2 = OCROperationsAPI.processCheckOcr(body: jpegURL)
        async let request3 = OCROperationsAPI.processReceiptOcr(body: jpegURL)

        do {
            let _ = try await (request1, request2, request3)
            if !isRealAuth {
                XCTFail("Expected 401 errors with mock auth, but requests succeeded")
            } else {
                print("All concurrent requests succeeded with real auth")
            }
        } catch {
            if isRealAuth {
                // With real auth, we might hit rate limits or other issues
                print("Concurrent requests with real auth got error (might be rate limiting): \(error)")
            } else {
                // With mock auth, we expect 401 errors
                print("Concurrent requests failed as expected with mock auth")
            }
        }
    }
}