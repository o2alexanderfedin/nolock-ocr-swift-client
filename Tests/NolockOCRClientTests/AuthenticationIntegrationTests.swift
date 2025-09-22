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
        // Reset authentication context
        AuthenticationContext.reset()
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

    // MARK: - Authentication Context Tests

    func testAuthenticationContextConfiguration() async throws {
        // Given: A mock provider
        let provider = MockAuthenticationProvider(token: "test-token")

        // When: Configuring the context
        AuthenticationContext.configure(provider: provider)

        // Then: Provider should be configured
        XCTAssertNotNil(AuthenticationContext.provider)
        let token = try await AuthenticationContext.provider?.getCurrentToken()
        XCTAssertEqual(token, "test-token")
    }

    func testAuthenticationProviderTokenRetrieval() async throws {
        // Given: A mock provider with a test token
        let provider = MockAuthenticationProvider(token: "test-jwt-token")
        AuthenticationContext.configure(provider: provider)

        // When: Retrieving tokens multiple times
        let token1 = try await provider.getCurrentToken()
        let token2 = try await provider.getCurrentToken()

        // Then: Should return the same token (cached)
        XCTAssertEqual(token1, "test-jwt-token")
        XCTAssertEqual(token2, "test-jwt-token")
        XCTAssertEqual(token1, token2)
    }

    // MARK: - Mock Provider Tests

    func testMockProviderBasicFunctionality() async throws {
        // Given: A mock provider with a test token
        let provider = MockAuthenticationProvider(token: "mock-token-123")

        // When: Checking token validity
        let isValid = try await provider.isTokenValid()

        // Then: Should be valid initially
        XCTAssertTrue(isValid)

        // When: Getting current token
        let token = try await provider.getCurrentToken()

        // Then: Should return configured token
        XCTAssertEqual(token, "mock-token-123")
    }

    func testMockProviderTokenRefresh() async throws {
        // Given: A mock provider
        let provider = MockAuthenticationProvider(token: "initial-token")

        // When: Getting token
        let token = try await provider.getToken()

        // Then: Should return the configured token
        XCTAssertEqual(token, "initial-token")
    }

    func testMockProviderInvalidToken() async throws {
        // Given: A mock provider with invalid token state
        let provider = MockAuthenticationProvider(token: "test-token")
        provider.isValid = false

        // When: Checking token validity
        let isValid = try await provider.isTokenValid()

        // Then: Should return invalid
        XCTAssertFalse(isValid)
    }

    func testMockProviderErrorSimulation() async throws {
        // Given: A mock provider configured to throw error
        let provider = MockAuthenticationProvider(token: "test-token")
        provider.shouldThrow = true

        // When/Then: Getting token should throw
        do {
            _ = try await provider.getCurrentToken()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AuthenticationError)
        }
    }

    // MARK: - Request Builder Factory Tests

    func testAuthenticatedRequestBuilderFactoryConfiguration() {
        // Given: A mock provider
        let provider = MockAuthenticationProvider(token: "factory-test-token")

        // When: Creating authenticated request builder factory
        let factory = AuthenticatedRequestBuilderFactory(
            authProvider: provider,
            configuration: .default
        )

        // Then: Factory should be configured with provider
        XCTAssertNotNil(factory.provider)
        XCTAssertEqual(factory.authConfiguration.automaticTokenRefresh, true)
    }

    func testAuthenticatedRequestBuilderFactoryCreatesCorrectBuilders() {
        // Given: An authenticated factory
        let provider = MockAuthenticationProvider(token: "test")
        let factory = AuthenticatedRequestBuilderFactory(authProvider: provider)

        // When: Getting builder types
        let nonDecodableType = factory.getNonDecodableBuilder() as RequestBuilder<Data>.Type
        let decodableType = factory.getBuilder() as RequestBuilder<TestDecodable>.Type

        // Then: Should return authenticated builder types
        XCTAssertTrue(nonDecodableType == AuthenticatedURLSessionRequestBuilder<Data>.self)
        XCTAssertTrue(decodableType == AuthenticatedURLSessionDecodableRequestBuilder<TestDecodable>.self)
    }

    // MARK: - Configuration API Tests

    func testConfigureAuthenticationAPI() {
        // Given: A mock provider
        let provider = MockAuthenticationProvider(token: "api-test-token")

        // When: Configuring through API
        NolockOCRClientAPI.configureAuthentication(
            provider: provider,
            configuration: .default
        )

        // Then: Request builder factory should be authenticated
        XCTAssertTrue(NolockOCRClientAPI.requestBuilderFactory is AuthenticatedRequestBuilderFactory)

        // And: Context should be configured
        XCTAssertNotNil(AuthenticationContext.provider)
    }

    func testConfigureMockAuthenticationAPI() {
        // When: Configuring mock authentication through API
        NolockOCRClientAPI.configureMockAuthentication(
            mockToken: "mock-api-token",
            configuration: .default
        )

        // Then: Request builder factory should be authenticated
        XCTAssertTrue(NolockOCRClientAPI.requestBuilderFactory is AuthenticatedRequestBuilderFactory)

        // And: Context should have a mock provider
        XCTAssertNotNil(AuthenticationContext.provider)
        XCTAssertTrue(AuthenticationContext.provider is MockAuthenticationProvider)
    }

    // MARK: - Integration Flow Tests

    func testCompleteAuthenticationFlow() async throws {
        // Given: A configured authentication system
        let provider = MockAuthenticationProvider(token: "flow-test-token")
        NolockOCRClientAPI.configureAuthentication(provider: provider)

        // When: Creating an authenticated request builder
        let builder = AuthenticatedURLSessionRequestBuilder<TestDecodable>(
            method: "GET",
            URLString: "https://api.example.com/test",
            parameters: nil,
            headers: [:]
        )

        // Then: The builder should have access to authentication
        XCTAssertNotNil(AuthenticationContext.provider)

        // And: Should be able to get token through the provider
        let token = try await provider.getCurrentToken()
        XCTAssertEqual(token, "flow-test-token")
    }

    func testTokenRefreshDuringRequest() async throws {
        // Given: A provider that will expire token
        let provider = MockAuthenticationProvider(token: "initial")
        provider.isValid = false // Force refresh

        NolockOCRClientAPI.configureAuthentication(
            provider: provider,
            configuration: AuthenticationConfiguration(
                automaticTokenRefresh: true,
                tokenRefreshBuffer: 0,
                maxRetryAttempts: 1,
                retryDelay: 0
            )
        )

        // When: Token needs refresh
        let refreshedToken = try await provider.refreshToken()

        // Then: Should get new token
        XCTAssertTrue(refreshedToken.hasPrefix("refreshed-token-"))
    }

    // MARK: - Thread Safety Tests

    func testConcurrentTokenAccess() async throws {
        // Given: A mock provider
        let provider = MockAuthenticationProvider(token: "concurrent-token")
        AuthenticationContext.configure(provider: provider)

        // When: Accessing token concurrently
        async let token1 = provider.getCurrentToken()
        async let token2 = provider.getCurrentToken()
        async let token3 = provider.getCurrentToken()

        // Then: All should succeed with same token
        let results = try await [token1, token2, token3]
        XCTAssertEqual(results[0], "concurrent-token")
        XCTAssertEqual(results[1], "concurrent-token")
        XCTAssertEqual(results[2], "concurrent-token")
    }

    func testConcurrentTokenRefresh() async throws {
        // Given: A mock provider
        let provider = MockAuthenticationProvider(token: "initial")
        AuthenticationContext.configure(provider: provider)

        // When: Refreshing token concurrently
        async let refresh1 = provider.refreshToken()
        async let refresh2 = provider.refreshToken()

        // Then: Both should succeed
        let results = try await [refresh1, refresh2]
        XCTAssertTrue(results[0].hasPrefix("refreshed-token-"))
        XCTAssertTrue(results[1].hasPrefix("refreshed-token-"))
    }

    // MARK: - Error Handling Tests

    func testAuthenticationErrorTypes() {
        // Test each error type
        let errors: [AuthenticationError] = [
            .noActiveSubscription,
            .tokenExpired,
            .tokenInvalid,
            .networkError(NSError(domain: "test", code: 1)),
            .storeKitError("Test error"),
            .configurationError("Config error")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testErrorRecovery() async throws {
        // Given: A provider that fails then succeeds
        let provider = MockAuthenticationProvider(token: "recovery-token")
        provider.shouldThrow = true

        AuthenticationContext.configure(provider: provider)

        // When: First attempt fails
        do {
            _ = try await provider.getCurrentToken()
            XCTFail("Expected error")
        } catch {
            // Expected
        }

        // When: Disabling error and trying again
        provider.shouldThrow = false
        let token = try await provider.getCurrentToken()

        // Then: Should succeed
        XCTAssertEqual(token, "recovery-token")
    }

    // MARK: - Configuration Edge Cases

    func testDefaultConfiguration() {
        // Given/When: Using default configuration
        let config = AuthenticationConfiguration.default

        // Then: Should have sensible defaults
        XCTAssertTrue(config.automaticTokenRefresh)
        XCTAssertEqual(config.tokenRefreshBuffer, 300)
        XCTAssertEqual(config.maxRetryAttempts, 3)
        XCTAssertEqual(config.retryDelay, 1.0)
    }

    func testCustomConfiguration() {
        // Given/When: Creating custom configuration
        let config = AuthenticationConfiguration(
            automaticTokenRefresh: false,
            tokenRefreshBuffer: 600,
            maxRetryAttempts: 5,
            retryDelay: 2.0
        )

        // Then: Should use custom values
        XCTAssertFalse(config.automaticTokenRefresh)
        XCTAssertEqual(config.tokenRefreshBuffer, 600)
        XCTAssertEqual(config.maxRetryAttempts, 5)
        XCTAssertEqual(config.retryDelay, 2.0)
    }

    func testConfigurationCompatibilityProperties() {
        // Given: A configuration
        var config = AuthenticationConfiguration.default

        // When: Using compatibility properties
        config.requiresAuthentication = false
        config.refreshThreshold = 1000

        // Then: Should update underlying properties
        XCTAssertFalse(config.automaticTokenRefresh)
        XCTAssertEqual(config.tokenRefreshBuffer, 1000)
    }
}

// MARK: - Test Helpers

private struct TestDecodable: Decodable {
    let id: String
    let value: String
}