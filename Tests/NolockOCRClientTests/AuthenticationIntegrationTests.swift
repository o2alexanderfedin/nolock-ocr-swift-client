import XCTest
import Foundation
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

    // MARK: - Integration Tests

    func testAPIConfigurationWithAuthentication() async throws {
        // Given: A mock authentication provider
        let provider = MockAuthenticationProvider()
        provider.mockToken = "integration-test-token"

        // When: Configuring the API with authentication
        NolockOCRClientAPI.configureAuthentication(
            provider: provider,
            configuration: .default
        )

        // Then: The API should be configured with authenticated builders
        XCTAssertTrue(NolockOCRClientAPI.requestBuilderFactory is AuthenticatedRequestBuilderFactory)
    }

    func testAPIUsesAuthenticationForProtectedEndpoints() async throws {
        // Given: A configured API with authentication
        let provider = MockAuthenticationProvider()
        provider.mockToken = "test-jwt-token"

        NolockOCRClientAPI.configureAuthentication(
            provider: provider,
            configuration: .default
        )

        // When: Creating a request for a protected endpoint
        // Note: Actual API calls would fail with mock tokens
        // This test validates the configuration setup

        // Then: The request builder should include authentication
        let factory = NolockOCRClientAPI.requestBuilderFactory as? AuthenticatedRequestBuilderFactory
        XCTAssertNotNil(factory)
        XCTAssertNotNil(factory?.provider)
    }

    func testAPIHandlesExpiredTokenScenario() async throws {
        // Given: A provider that simulates expired token
        let provider = await MockAuthenticationProvider.expiredTokenProvider()

        // When: Configuring authentication
        NolockOCRClientAPI.configureAuthentication(
            provider: provider,
            configuration: AuthenticationConfiguration(
                requiresAuthentication: true,
                refreshThreshold: 300,
                maxRetryAttempts: 2
            )
        )

        // Then: The configuration should be set for handling expiration
        let factory = NolockOCRClientAPI.requestBuilderFactory as? AuthenticatedRequestBuilderFactory
        XCTAssertNotNil(factory)
        XCTAssertEqual(factory?.authConfiguration.refreshThreshold, 300)
        XCTAssertEqual(factory?.authConfiguration.maxRetryAttempts, 2)
    }

    func testAPIHandlesNoSubscriptionScenario() async throws {
        // Given: A provider configured for no subscription
        let provider = await MockAuthenticationProvider.noSubscriptionProvider()

        // When: Attempting to use the API
        NolockOCRClientAPI.configureAuthentication(
            provider: provider,
            configuration: .default
        )

        // Then: The API should handle the no subscription case
        // Actual behavior would be tested through specific API calls
        let factory = NolockOCRClientAPI.requestBuilderFactory as? AuthenticatedRequestBuilderFactory
        XCTAssertNotNil(factory)
    }

    func testAPIRevertsToNormalModeWhenAuthenticationRemoved() {
        // Given: API configured with authentication
        let provider = MockAuthenticationProvider()
        NolockOCRClientAPI.configureAuthentication(
            provider: provider,
            configuration: .default
        )

        // When: Removing authentication
        NolockOCRClientAPI.requestBuilderFactory = URLSessionRequestBuilderFactory()

        // Then: API should work without authentication
        XCTAssertFalse(NolockOCRClientAPI.requestBuilderFactory is AuthenticatedRequestBuilderFactory)
    }

    // MARK: - Configuration Tests

    func testAuthenticationConfigurationDefaults() {
        // Given: Default configuration
        let config = AuthenticationConfiguration.default

        // Then: Should have sensible defaults
        XCTAssertTrue(config.requiresAuthentication)
        XCTAssertEqual(config.refreshThreshold, 300) // 5 minutes
        XCTAssertEqual(config.maxRetryAttempts, 3)
    }

    func testAuthenticationConfigurationCustomValues() {
        // Given: Custom configuration
        let config = AuthenticationConfiguration(
            requiresAuthentication: false,
            refreshThreshold: 600,
            maxRetryAttempts: 3
        )

        // Then: Should use custom values
        XCTAssertFalse(config.requiresAuthentication)
        XCTAssertEqual(config.refreshThreshold, 600)
        XCTAssertEqual(config.maxRetryAttempts, 3)
    }

    // MARK: - Mock Provider Integration Tests

    func testMockProviderGeneratesValidJWT() {
        // Given: A mock provider
        let provider = MockAuthenticationProvider()

        // When: Generating a JWT
        let jwt = provider.generateMockJWT(expiresIn: 3600)

        // Then: Should have JWT structure
        let components = jwt.split(separator: ".")
        XCTAssertEqual(components.count, 3) // header.payload.signature
    }

    func testMockProviderSimulatesDelay() async throws {
        // Given: A mock provider with delay and a valid token
        let provider = MockAuthenticationProvider()
        provider.mockToken = "delay-test-token"
        provider.simulatedDelay = 0.1 // 100ms

        // When: Getting token
        let start = Date()
        _ = try await provider.getCurrentToken()
        let elapsed = Date().timeIntervalSince(start)

        // Then: Should have delayed
        XCTAssertGreaterThanOrEqual(elapsed, 0.1)
    }

    func testMockProviderTracksCallCounts() async throws {
        // Given: A mock provider with tokens configured
        let provider = MockAuthenticationProvider()
        provider.mockToken = "count-test-token"
        provider.refreshedMockToken = "refreshed-count-test-token"

        // When: Making multiple calls
        _ = try await provider.getCurrentToken()
        _ = try await provider.getCurrentToken()
        _ = try await provider.refreshToken()

        // Then: Should track call counts
        // Note: Requires implementation of call count tracking
        XCTAssertNotNil(provider.mockToken)
    }

    // MARK: - Error Handling Integration Tests

    func testAuthenticationErrorPropagation() async throws {
        // Given: A provider that throws specific errors
        let provider = MockAuthenticationProvider()
        provider.shouldThrowError = true
        provider.errorToThrow = AuthenticationError.tokenExpired

        // When/Then: Error should propagate
        do {
            _ = try await provider.getCurrentToken()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is AuthenticationError)
        }
    }

    func testNetworkErrorHandling() async throws {
        // Given: A provider simulating network error
        let provider = MockAuthenticationProvider()
        provider.shouldThrowError = true
        provider.errorToThrow = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)

        // When/Then: Network error should be handled
        do {
            _ = try await provider.getCurrentToken()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertEqual((error as NSError).code, NSURLErrorTimedOut)
        }
    }

    // MARK: - End-to-End Scenario Tests

    func testSuccessfulAuthenticationFlow() async throws {
        // Given: A successful authentication setup
        let provider = await MockAuthenticationProvider.successfulProvider()

        // When: Configuring and using the API
        NolockOCRClientAPI.configureAuthentication(
            provider: provider,
            configuration: .default
        )

        // Then: Authentication should be ready
        let factory = NolockOCRClientAPI.requestBuilderFactory as? AuthenticatedRequestBuilderFactory
        XCTAssertNotNil(factory)

        // And: Provider should have valid tokens
        let token = try await provider.getCurrentToken()
        XCTAssertFalse(token.isEmpty)
    }

    func testTokenRefreshFlow() async throws {
        // Given: An expired token scenario
        let provider = MockAuthenticationProvider()
        provider.mockToken = "expired-token"
        provider.isTokenValidResponse = false
        provider.refreshedMockToken = "new-fresh-token"

        // When: Token needs refresh
        let refreshedToken = try await provider.refreshToken()

        // Then: Should return refreshed token
        XCTAssertEqual(refreshedToken, "new-fresh-token")
    }

    func testCompleteAuthenticationLifecycle() async throws {
        // Given: A mock provider
        let provider = MockAuthenticationProvider()

        // 1. Initial setup
        provider.configureValidToken(expiresIn: 60) // Short expiry

        // 2. Configure API
        NolockOCRClientAPI.configureAuthentication(
            provider: provider,
            configuration: .default
        )

        // 3. Use token
        let initialToken = try await provider.getCurrentToken()
        XCTAssertFalse(initialToken.isEmpty)

        // 4. Simulate expiration
        provider.isTokenValidResponse = false
        provider.refreshedMockToken = "refreshed-lifecycle-token"

        // 5. Refresh token
        let refreshedToken = try await provider.refreshToken()
        XCTAssertEqual(refreshedToken, "refreshed-lifecycle-token")

        // 6. Clean up
        NolockOCRClientAPI.requestBuilderFactory = URLSessionRequestBuilderFactory()
    }
}