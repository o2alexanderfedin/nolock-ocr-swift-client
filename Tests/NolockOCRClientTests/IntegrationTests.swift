import XCTest
@testable import NolockOCRClient

/// Essential integration tests to verify token → auth → server flow
final class IntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Ensure we're pointed at the real server
        NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
    }

    // MARK: - Integration Tests

    /// Test health endpoint (no auth required)
    func testHealthCheck() async throws {
        let response = try await HealthAPI.healthCheck()
        XCTAssertNotNil(response, "Health check should return a response")
    }

    /// Test check OCR with authentication flow
    func testCheckOCRIntegration() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test image not found")
            return
        }

        // Convert HEIC to JPEG (iOS-specific requirement)
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }

        // Check if we have real authentication available
        let shouldSucceed = await TestAuthenticationHelper.shouldExpectSuccess()

        do {
            let response = try await OCROperationsAPI.processCheckOcr(body: jpegURL)
            if shouldSucceed {
                XCTAssertNotNil(response.modelData, "Should have OCR data with valid auth")
            } else {
                XCTFail("Expected error without auth, but request succeeded")
            }
        } catch {
            if shouldSucceed {
                XCTFail("Expected success with auth, but got error: \(error)")
            } else {
                // Expected error when no auth available
                XCTAssertNotNil(error, "Expected error without auth")
            }
        }
    }

    /// Test receipt OCR with authentication flow
    func testReceiptOCRIntegration() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test image not found")
            return
        }

        // Convert HEIC to JPEG (iOS-specific requirement)
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }

        // Check if we have real authentication available
        let shouldSucceed = await TestAuthenticationHelper.shouldExpectSuccess()

        do {
            let response = try await OCROperationsAPI.processReceiptOcr(body: jpegURL)
            if shouldSucceed {
                XCTAssertNotNil(response.modelData, "Should have OCR data with valid auth")
            } else {
                XCTFail("Expected error without auth, but request succeeded")
            }
        } catch {
            if shouldSucceed {
                XCTFail("Expected success with auth, but got error: \(error)")
            } else {
                // Expected error when no auth available
                XCTAssertNotNil(error, "Expected error without auth")
            }
        }
    }
}