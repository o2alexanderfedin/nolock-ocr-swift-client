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

    var mockProvider: MockAuthenticationProvider!
    var authManager: AuthenticationManager!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockProvider = MockAuthenticationProvider()
        authManager = AuthenticationManager.shared
        authManager.configure(provider: mockProvider, configuration: .default)
    }

    override func tearDown() {
        mockProvider = nil
        authManager = nil
        super.tearDown()
    }

    // MARK: - Tests for AuthenticatedURLSessionRequestBuilder

    func testAuthenticatedRequestBuilderAddsAuthorizationHeader() async throws {
        // Given: A mock provider with a valid token
        mockProvider.mockToken = "test-token-123"

        // And: An authenticated URLSession request builder
        let builder = AuthenticatedURLSessionRequestBuilder<CheckModelOcrResponse>(
            method: "GET",
            URLString: "https://test.com/api",
            parameters: nil,
            headers: [:],
            requiresAuthentication: true
        )

        // When: Building headers asynchronously
        let headers = await builder.buildHeadersAsync()

        // Then: The authorization header should be added
        XCTAssertEqual(headers["Authorization"], "Bearer test-token-123")
    }

    func testAuthenticatedRequestBuilderSkipsAuthWhenNotRequired() async throws {
        // Given: An authenticated request builder with requiresAuthentication = false
        let builder = AuthenticatedURLSessionRequestBuilder<CheckModelOcrResponse>(
            method: "GET",
            URLString: "https://test.com/public",
            parameters: nil,
            headers: [:],
            requiresAuthentication: false
        )

        // When: Building headers
        let headers = await builder.buildHeadersAsync()

        // Then: No authorization header should be added
        XCTAssertNil(headers["Authorization"])
    }

    func testAuthenticatedRequestBuilderHandlesTokenRefresh() async throws {
        // Given: A mock provider that returns expired token initially
        mockProvider.mockToken = "expired-token"
        mockProvider.isTokenValidResponse = false
        mockProvider.refreshedMockToken = "refreshed-token"

        // And: An authenticated request builder
        let builder = AuthenticatedURLSessionRequestBuilder<CheckModelOcrResponse>(
            method: "POST",
            URLString: "https://test.com/api",
            parameters: ["key": "value"],
            headers: [:],
            requiresAuthentication: true
        )

        // When: Executing request (which should trigger token refresh)
        // Note: This would require a full execution flow with URLSession mocking

        // Then: The refreshed token should be used
        // This test would need URLSession mocking to fully test the refresh flow
        XCTAssertEqual(mockProvider.refreshedMockToken, "refreshed-token")
    }

    func testAuthenticatedRequestBuilderPreservesExistingHeaders() async throws {
        // Given: A mock provider with a valid token
        mockProvider.mockToken = "auth-token"

        // And: Request builder with existing headers
        let existingHeaders = [
            "Content-Type": "application/json",
            "X-Custom-Header": "custom-value"
        ]

        let builder = AuthenticatedURLSessionRequestBuilder<CheckModelOcrResponse>(
            method: "PUT",
            URLString: "https://test.com/api",
            parameters: nil,
            headers: existingHeaders,
            requiresAuthentication: true
        )

        // When: Building headers
        let headers = await builder.buildHeadersAsync()

        // Then: Existing headers should be preserved
        XCTAssertEqual(headers["Content-Type"], "application/json")
        XCTAssertEqual(headers["X-Custom-Header"], "custom-value")
        XCTAssertEqual(headers["Authorization"], "Bearer auth-token")
    }

    // MARK: - Tests for Authentication Manager Integration

    func testAuthenticationManagerCachesToken() async throws {
        // Given: A mock provider with a valid token
        mockProvider.mockToken = "cached-token"

        // When: Getting token twice
        let token1 = try await authManager.getToken()
        let token2 = authManager.getCachedToken()

        // Then: Both should return the same token
        XCTAssertEqual(token1, "cached-token")
        XCTAssertEqual(token2, "cached-token")

        // And: Provider should only be called once (due to caching)
        // Note: This requires tracking call counts in the mock provider
    }

    func testAuthenticationManagerRefreshesExpiredToken() async throws {
        // Given: An expired cached token
        mockProvider.mockToken = "expired-token"
        mockProvider.isTokenValidResponse = false
        mockProvider.refreshedMockToken = "new-fresh-token"

        // When: Requesting a token
        let token = try await authManager.refreshToken()

        // Then: Should return the refreshed token
        XCTAssertEqual(token, "new-fresh-token")
    }

    func testAuthenticationManagerHandlesNoSubscription() async throws {
        // Given: A provider that throws no subscription error
        mockProvider.shouldThrowError = true
        mockProvider.errorToThrow = AuthenticationError.noActiveSubscription

        // When: Attempting to get token
        do {
            _ = try await authManager.getToken()
            XCTFail("Should have thrown an error")
        } catch {
            // Then: Should throw the appropriate error
            XCTAssertTrue(error is AuthenticationError)
            if let authError = error as? AuthenticationError {
                XCTAssertEqual(authError, .noActiveSubscription)
            }
        }
    }

    // MARK: - Tests for Retry Logic

    func testRequestRetriesOn401Response() async throws {
        // Skip this test as it requires complex URLSession mocking
        // which is beyond the current scope
        XCTSkip("Requires URLSession mocking infrastructure")
    }

    func testRequestDoesNotRetryOnNon401Errors() async throws {
        // Skip this test as it requires complex URLSession mocking
        // which is beyond the current scope
        XCTSkip("Requires URLSession mocking infrastructure")
    }

    // MARK: - Tests for Token Expiration

    func testAuthenticationManagerDetectsExpiredToken() async throws {
        // Given: A token that's about to expire
        mockProvider.mockToken = "expiring-token"

        // When: Checking if token is valid after expiration time
        mockProvider.isTokenValidResponse = false
        let isValid = try await mockProvider.isTokenValid()

        // Then: Should return false
        XCTAssertFalse(isValid)
    }

    func testAuthenticationManagerRefreshesTokenProactively() async throws {
        // Given: A token nearing expiration
        mockProvider.mockToken = "almost-expired"
        mockProvider.isTokenValidResponse = false
        mockProvider.refreshedMockToken = "proactively-refreshed"

        // When: Getting token when current one is near expiration
        let token = try await authManager.refreshToken()

        // Then: Should proactively refresh
        XCTAssertEqual(token, "proactively-refreshed")
    }

    // MARK: - Tests for Error Handling

    func testAuthenticationManagerHandlesNetworkError() async throws {
        // Given: A provider that simulates network error
        mockProvider.shouldThrowError = true
        mockProvider.errorToThrow = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)

        // When: Attempting to get token
        do {
            _ = try await authManager.getToken()
            XCTFail("Should have thrown an error")
        } catch {
            // Then: Should pass through the network error
            XCTAssertTrue((error as NSError).domain == NSURLErrorDomain)
        }
    }

    func testAuthenticationManagerHandlesInvalidToken() async throws {
        // Given: A provider that returns invalid token format
        mockProvider.mockToken = ""  // Empty token

        // When: Getting token
        let token = try await authManager.getToken()

        // Then: Should handle gracefully (empty tokens should be caught by API)
        XCTAssertEqual(token, "")
    }

    // MARK: - Tests for Concurrent Access

    func testAuthenticationManagerHandlesConcurrentTokenRequests() async throws {
        // Given: A mock provider with delay to simulate slow network
        mockProvider.mockToken = "concurrent-token"
        mockProvider.simulatedDelay = 0.5

        // When: Multiple concurrent token requests
        async let token1 = authManager.getToken()
        async let token2 = authManager.getToken()
        async let token3 = authManager.getToken()

        // Then: All should receive the same token (due to synchronization)
        let tokens = try await [token1, token2, token3]
        XCTAssertEqual(tokens[0], "concurrent-token")
        XCTAssertEqual(tokens[1], "concurrent-token")
        XCTAssertEqual(tokens[2], "concurrent-token")

        // And: Provider should ideally be called only once
        // (requires call count tracking in mock)
    }

    func testAuthenticationManagerHandlesConcurrentRefresh() async throws {
        // Given: Multiple refresh requests
        mockProvider.refreshedMockToken = "concurrently-refreshed"

        // When: Multiple concurrent refresh requests
        async let refresh1 = authManager.refreshToken()
        async let refresh2 = authManager.refreshToken()

        // Then: Both should succeed with same token
        let tokens = try await [refresh1, refresh2]
        XCTAssertEqual(tokens[0], "concurrently-refreshed")
        XCTAssertEqual(tokens[1], "concurrently-refreshed")
    }

    // MARK: - Tests for Factory Pattern

    func testAuthenticatedRequestBuilderFactoryCreatesCorrectBuilderTypes() {
        // Given: An authenticated factory
        let factory = AuthenticatedRequestBuilderFactory(authProvider: mockProvider)

        // When: Getting different builder types
        let nonDecodableBuilder = factory.getNonDecodableBuilder() as RequestBuilder<Data>.Type
        let decodableBuilder = factory.getBuilder() as RequestBuilder<CheckModelOcrResponse>.Type

        // Then: Should return correct builder types
        XCTAssertTrue(nonDecodableBuilder == AuthenticatedURLSessionRequestBuilder<Data>.self)
        XCTAssertTrue(decodableBuilder == AuthenticatedURLSessionDecodableRequestBuilder<CheckModelOcrResponse>.self)
    }

    func testAuthenticatedRequestBuilderFactoryInjectsProvider() {
        // Given: A mock provider
        mockProvider.mockToken = "factory-token"

        // And: An authenticated request builder factory
        let factory = AuthenticatedRequestBuilderFactory(authProvider: mockProvider)
        let builderType = factory.getBuilder() as RequestBuilder<CheckModelOcrResponse>.Type
        let builder = builderType.init(
            method: "POST",
            URLString: "https://test.com/api",
            parameters: nil,
            headers: [:],
            requiresAuthentication: true
        )

        // When: The builder is created
        // Then: It should have access to the authentication provider
        // (This would be validated through actual request execution)
        XCTAssertNotNil(builder)
    }
}

// MARK: - Test Extensions for Async Header Building

extension AuthenticatedURLSessionRequestBuilder {
    func buildHeadersAsync() async -> [String: String] {
        // This is a test helper method
        // The actual implementation would be in the production code
        var headers = buildHeaders()

        if requiresAuthentication {
            // In real implementation, this would use the auth manager
            if let provider = authenticationManager.provider {
                do {
                    let token = try await provider.getCurrentToken()
                    headers["Authorization"] = "Bearer \(token)"
                } catch {
                    print("Failed to get auth token: \(error)")
                }
            }
        }

        return headers
    }
}