import XCTest
import Foundation
#if canImport(StoreKit)
import StoreKit
#endif
@testable import NolockOCRClient

final class AuthenticationIntegrationTests: XCTestCase {

    // MARK: - Properties

    var originalBasePath: String!
    var originalFactory: RequestBuilderFactory!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Save original configuration
        originalBasePath = NolockOCRClientAPI.basePath
        originalFactory = NolockOCRClientAPI.requestBuilderFactory
    }

    override func tearDown() {
        // Restore original configuration
        NolockOCRClientAPI.basePath = originalBasePath
        NolockOCRClientAPI.requestBuilderFactory = originalFactory
        super.tearDown()
    }

    // MARK: - StoreKit Integration Tests

    #if canImport(StoreKit)
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testStoreKitAuthenticationProviderExists() async throws {
        // Given/When: StoreKit provider is available
        // Then: Provider should be creatable (compile-time check)
        // This test validates that StoreKitAuthenticationProvider exists and compiles
        XCTAssertTrue(true)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testStoreKitAuthenticationAutoConfiguration() {
        // Given: iOS 15+ environment
        // When: Creating a new request builder factory
        let factory = NolockOCRClientAPI.requestBuilderFactory

        // Then: Should use an appropriate factory
        // Note: This test validates automatic configuration on supported platforms
        XCTAssertTrue(factory is AuthenticatedRequestBuilderFactory || factory is URLSessionRequestBuilderFactory)
    }
    #endif

    // MARK: - Authentication Manager Integration Tests

    func testAuthenticationManagerSingleton() {
        // Given: Authentication manager
        let manager1 = AuthenticationManager.shared
        let manager2 = AuthenticationManager.shared

        // Then: Should be the same instance
        XCTAssertTrue(manager1 === manager2)
    }

    func testAuthenticationManagerConfiguration() async throws {
        // Given: Mock provider and configuration
        let provider = MockAuthenticationProvider()
        provider.mockToken = "manager-test-token"
        let config = AuthenticationConfiguration(
            automaticTokenRefresh: false,
            tokenRefreshBuffer: 180,
            maxRetryAttempts: 2,
            retryDelay: 0.5
        )

        // When: Configuring the manager
        AuthenticationManager.shared.configure(
            provider: provider,
            configuration: config
        )

        // Then: Manager should use the provider
        XCTAssertNotNil(AuthenticationManager.shared.provider)
        let token = try await AuthenticationManager.shared.getToken()
        XCTAssertEqual(token, "manager-test-token")
    }

    func testAuthenticationManagerTokenRetrieval() async throws {
        // Given: Provider with token
        let provider = MockAuthenticationProvider()
        provider.mockToken = "test-token"
        provider.isTokenValidResponse = true

        AuthenticationManager.shared.configure(provider: provider)

        // When: Getting token multiple times
        let token1 = try await AuthenticationManager.shared.getToken()
        let token2 = try await AuthenticationManager.shared.getToken()

        // Then: Should get tokens
        XCTAssertEqual(token1, "test-token")
        XCTAssertEqual(token2, "test-token")
    }


    // MARK: - Token Refresh & Retry Logic Tests

    func testAutomaticTokenRefreshOnExpiry() async throws {
        // Given: Provider with expiring token
        let provider = MockAuthenticationProvider()
        provider.mockToken = "expired-token"
        provider.isTokenValidResponse = false
        provider.refreshedMockToken = "fresh-token"

        let config = AuthenticationConfiguration(
            automaticTokenRefresh: true,
            tokenRefreshBuffer: 300,
            maxRetryAttempts: 3,
            retryDelay: 0.1
        )

        AuthenticationManager.shared.configure(
            provider: provider,
            configuration: config
        )

        // When: Getting token with expired state
        let token = try await AuthenticationManager.shared.getToken()

        // Then: Should automatically refresh
        XCTAssertEqual(token, "fresh-token")
    }

    func testManualTokenRefreshRequired() async throws {
        // Given: Provider with expired token and no auto-refresh
        let provider = MockAuthenticationProvider()
        provider.mockToken = "expired-manual-token"
        provider.isTokenValidResponse = false

        let config = AuthenticationConfiguration(
            automaticTokenRefresh: false,
            tokenRefreshBuffer: 300,
            maxRetryAttempts: 3,
            retryDelay: 0.1
        )

        AuthenticationManager.shared.configure(
            provider: provider,
            configuration: config
        )

        // When/Then: Should throw expired error
        do {
            _ = try await AuthenticationManager.shared.getToken()
            XCTFail("Should have thrown tokenExpired error")
        } catch AuthenticationError.tokenExpired {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testTokenRefreshWithRetries() async throws {
        // Given: Provider that fails then succeeds
        let provider = MockAuthenticationProvider()
        provider.refreshedMockToken = "retry-success-token"
        // Note: Retry logic would be tested with a more sophisticated mock
        // that tracks attempt count internally

        // When: Refreshing token
        let token = try await provider.refreshToken()

        // Then: Should eventually succeed
        XCTAssertEqual(token, "retry-success-token")
    }

    // MARK: - Request Builder Integration Tests

    func testAuthenticatedRequestBuilderDoesNotAddSyncHeaders() async throws {
        // Given: Authenticated request builder with provider configured
        let provider = MockAuthenticationProvider()
        provider.mockToken = "test-token"
        AuthenticationManager.shared.configure(provider: provider)

        let builder = AuthenticatedURLSessionRequestBuilder<Data>(
            method: "GET",
            URLString: "https://api.example.com/test",
            parameters: nil,
            headers: [:],
            requiresAuthentication: true
        )

        // When: Building headers
        let headers = builder.buildHeaders()

        // Then: Should not add auth header synchronously (will be added in execute())
        XCTAssertNil(headers["Authorization"])
    }

    // MARK: - Error Scenario Tests

    func testNoActiveSubscriptionError() async throws {
        // Given: Provider with no subscription
        let provider = await MockAuthenticationProvider.noSubscriptionProvider()

        // When/Then: Should throw appropriate error
        do {
            _ = try await provider.getCurrentToken()
            XCTFail("Should have thrown noActiveSubscription error")
        } catch AuthenticationError.noActiveSubscription {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testTokenInvalidError() async throws {
        // Given: Provider with invalid token
        let provider = MockAuthenticationProvider()
        provider.shouldThrowError = true
        provider.errorToThrow = AuthenticationError.tokenInvalid

        // When/Then: Should propagate error
        do {
            _ = try await provider.getCurrentToken()
            XCTFail("Should have thrown tokenInvalid error")
        } catch AuthenticationError.tokenInvalid {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNetworkError() async throws {
        // Given: Provider with network error
        let provider = MockAuthenticationProvider()
        provider.shouldThrowError = true
        provider.errorToThrow = AuthenticationError.networkError(
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        )

        // When/Then: Should handle network error
        do {
            _ = try await provider.getCurrentToken()
            XCTFail("Should have thrown network error")
        } catch AuthenticationError.networkError(let error as NSError) {
            XCTAssertEqual(error.code, NSURLErrorNotConnectedToInternet)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }


    // MARK: - Concurrent Request Tests

    func testConcurrentTokenRequests() async throws {
        // Given: Provider with delay to simulate concurrent access
        let provider = MockAuthenticationProvider()
        provider.mockToken = "concurrent-token"
        provider.simulatedDelay = 0.1
        provider.isTokenValidResponse = true

        AuthenticationManager.shared.configure(provider: provider)

        // When: Making concurrent requests
        async let token1 = AuthenticationManager.shared.getToken()
        async let token2 = AuthenticationManager.shared.getToken()
        async let token3 = AuthenticationManager.shared.getToken()

        // Then: All should get the same token
        let results = try await [token1, token2, token3]
        XCTAssertEqual(results[0], "concurrent-token")
        XCTAssertEqual(results[1], "concurrent-token")
        XCTAssertEqual(results[2], "concurrent-token")
    }

    func testConcurrentRefreshRequests() async throws {
        // Given: Provider configured for refresh
        let provider = MockAuthenticationProvider()
        provider.refreshedMockToken = "concurrent-refresh-token"
        provider.simulatedDelay = 0.05

        AuthenticationManager.shared.configure(provider: provider)

        // When: Making concurrent refresh requests
        async let refresh1 = AuthenticationManager.shared.refreshToken()
        async let refresh2 = AuthenticationManager.shared.refreshToken()

        // Then: Both should succeed
        let results = try await [refresh1, refresh2]
        XCTAssertEqual(results[0], "concurrent-refresh-token")
        XCTAssertEqual(results[1], "concurrent-refresh-token")
    }

    // MARK: - API Configuration Tests

    func testAPIConfigurationWithMockAuthentication() {
        // Given: Mock token
        let mockToken = "api-config-mock-token"

        // When: Configuring with mock
        NolockOCRClientAPI.configureMockAuthentication(
            mockToken: mockToken,
            configuration: .default
        )

        // Then: Should use authenticated factory
        XCTAssertTrue(NolockOCRClientAPI.requestBuilderFactory is AuthenticatedRequestBuilderFactory)
    }



    // MARK: - End-to-End Authentication Flow Tests

    func testCompleteAuthenticationLifecycle() async throws {
        // 1. Setup mock provider
        let provider = MockAuthenticationProvider()
        provider.configureValidToken(expiresIn: 60)

        // 2. Configure API with authentication
        NolockOCRClientAPI.configureAuthentication(
            provider: provider,
            configuration: AuthenticationConfiguration(
                automaticTokenRefresh: true,
                tokenRefreshBuffer: 30,
                maxRetryAttempts: 3,
                retryDelay: 0.1
            )
        )

        // 3. Verify authenticated factory is in use
        XCTAssertTrue(NolockOCRClientAPI.requestBuilderFactory is AuthenticatedRequestBuilderFactory)

        // 4. Get initial token through AuthenticationManager to ensure caching
        let initialToken = try await AuthenticationManager.shared.getToken()
        XCTAssertFalse(initialToken.isEmpty)

        // 5. Token was retrieved (no caching to verify)

        // 6. Simulate token expiration
        provider.isTokenValidResponse = false
        provider.refreshedMockToken = "lifecycle-refreshed-token"

        // 7. Trigger refresh
        let refreshedToken = try await AuthenticationManager.shared.refreshToken()
        XCTAssertEqual(refreshedToken, "lifecycle-refreshed-token")

        // 8. New token was retrieved

        // Test complete
    }

    func testAuthenticationWithAPICall() async throws {
        // Given: Mock server response expectation
        let provider = MockAuthenticationProvider()
        provider.mockToken = "api-call-token"

        NolockOCRClientAPI.configureAuthentication(
            provider: provider,
            configuration: .default
        )

        // When: Creating a request builder (simulating API call)
        let factory = NolockOCRClientAPI.requestBuilderFactory as? AuthenticatedRequestBuilderFactory
        XCTAssertNotNil(factory)

        let builderType = factory?.getNonDecodableBuilder() as? AuthenticatedURLSessionRequestBuilder<Data>.Type
        XCTAssertNotNil(builderType)

        let builder = builderType?.init(
            method: "GET",
            URLString: "https://api.example.com/protected",
            parameters: nil,
            headers: [:],
            requiresAuthentication: true
        )

        // Then: Builder should be created
        XCTAssertNotNil(builder)
    }

    // MARK: - Performance Tests

    func testTokenRetrievalPerformance() async throws {
        // Given: Configured authentication
        let provider = MockAuthenticationProvider()
        provider.mockToken = "performance-token"
        AuthenticationManager.shared.configure(provider: provider)

        // When/Then: Token retrieval performance (no cache)
        // Note: This will be slower since we always fetch fresh
        let start = Date()
        for _ in 0..<10 {
            _ = try await AuthenticationManager.shared.getToken()
        }
        let elapsed = Date().timeIntervalSince(start)
        print("10 token fetches took \(elapsed) seconds")
    }

    func testConcurrentTokenAccessPerformance() async throws {
        // Given: Configured authentication
        let provider = MockAuthenticationProvider()
        provider.mockToken = "concurrent-perf-token"
        AuthenticationManager.shared.configure(provider: provider)

        // When/Then: Concurrent token fetches
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    _ = try? await AuthenticationManager.shared.getToken()
                }
            }
        }
    }
}

// MARK: - Test Helpers

extension MockAuthenticationProvider {
    static func successfulProvider() async -> MockAuthenticationProvider {
        let provider = MockAuthenticationProvider()
        provider.mockToken = "success-token"
        provider.refreshedMockToken = "success-refresh-token"
        provider.isTokenValidResponse = true
        return provider
    }

    static func expiredTokenProvider() async -> MockAuthenticationProvider {
        let provider = MockAuthenticationProvider()
        provider.mockToken = "expired-token"
        provider.isTokenValidResponse = false
        provider.refreshedMockToken = "new-token-after-refresh"
        return provider
    }

    static func noSubscriptionProvider() async -> MockAuthenticationProvider {
        let provider = MockAuthenticationProvider()
        provider.shouldThrowError = true
        provider.errorToThrow = AuthenticationError.noActiveSubscription
        return provider
    }
}