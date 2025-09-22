import XCTest
import Foundation
@testable import NolockOCRClient

// Mock Response Model
struct CheckModelOcrResponse: Codable {
    let status: String
    let message: String?
    let data: [String: String]?
}

final class AuthenticatedRequestBuilderTests: XCTestCase {

    // MARK: - Properties

    var mockProvider: MockTokenProvider!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockProvider = MockTokenProvider()
        // Reset to default factory
        NolockOCRClientAPI.requestBuilderFactory = URLSessionRequestBuilderFactory()
    }

    override func tearDown() {
        mockProvider = nil
        NolockOCRClientAPI.requestBuilderFactory = URLSessionRequestBuilderFactory()
        super.tearDown()
    }

    // MARK: - Tests for AuthenticatedRequestBuilderFactory

    func testAuthenticatedRequestBuilderFactoryCreatesCorrectBuilderTypes() {
        // Given: An authenticated factory
        let factory = AuthenticatedRequestBuilderFactory(tokenProvider: mockProvider)

        // When: Getting different builder types
        let nonDecodableBuilder = factory.getNonDecodableBuilder() as RequestBuilder<Data>.Type
        let decodableBuilder = factory.getBuilder() as RequestBuilder<CheckModelOcrResponse>.Type

        // Then: Should return correct builder types
        XCTAssertTrue(nonDecodableBuilder == AuthenticatedURLSessionRequestBuilder<Data>.self)
        XCTAssertTrue(decodableBuilder == AuthenticatedDecodableRequestBuilder<CheckModelOcrResponse>.self)
    }

    func testAuthenticatedRequestBuilderFactoryStoresTokenProvider() {
        // Given: A mock provider
        let factory = AuthenticatedRequestBuilderFactory(tokenProvider: mockProvider)

        // Then: Factory should have the token provider
        XCTAssertNotNil(factory.tokenProvider)
    }

    // MARK: - Tests for Direct Request Builder Creation

    func testDirectRequestBuilderCreationWithTokenProvider() {
        // Given: A direct request builder with token provider
        let builder = AuthenticatedURLSessionRequestBuilder<CheckModelOcrResponse>(
            method: "POST",
            URLString: "https://test.com/api",
            parameters: nil,
            headers: [:],
            tokenProvider: mockProvider
        )

        // Then: Builder should be created
        XCTAssertNotNil(builder)
        XCTAssertEqual(builder.method, "POST")
        XCTAssertEqual(builder.URLString, "https://test.com/api")
    }

    // MARK: - Tests for Token Provider

    func testTokenProviderReturnsToken() async throws {
        // Given: A mock provider
        // When: Getting token
        let token = try await mockProvider.getToken()

        // Then: Should return a UUID token
        XCTAssertFalse(token.isEmpty)
        // MockTokenProvider returns UUIDs
        XCTAssertTrue(UUID(uuidString: token) != nil, "Token should be a valid UUID")
    }

    func testTokenProviderAlwaysSucceeds() async throws {
        // MockTokenProvider always returns a valid UUID token
        // When: Getting token multiple times
        let token1 = try await mockProvider.getToken()
        let token2 = try await mockProvider.getToken()

        // Then: Should always return valid UUID tokens
        XCTAssertTrue(UUID(uuidString: token1) != nil)
        XCTAssertTrue(UUID(uuidString: token2) != nil)
        // Each call returns a different UUID
        XCTAssertNotEqual(token1, token2)
    }

    // MARK: - Tests for OCR Operations Integration

    func testOCROperationUsesProvidedTokenProvider() async throws {
        // This would test the actual OCR operation with a mock provider
        // Requires a test image URL
        let testImageURL = URL(fileURLWithPath: "/tmp/test.jpg")

        // Create a test file
        let testData = Data([0xFF, 0xD8, 0xFF]) // JPEG header
        try testData.write(to: testImageURL)
        defer { try? FileManager.default.removeItem(at: testImageURL) }

        // The actual API call would fail without a real server
        // This just tests that the method accepts the token provider
        let builder = OCROperationsAPI.processCheckOcrWithRequestBuilder(
            body: testImageURL,
            tokenProvider: mockProvider
        )

        XCTAssertNotNil(builder)
    }
}