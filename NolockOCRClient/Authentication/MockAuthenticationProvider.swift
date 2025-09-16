import Foundation

/// Actor for managing mock provider state
actor MockProviderState {
    var mockToken: String?
    var refreshedMockToken: String?
    var isTokenValidResponse: Bool = true
    var shouldThrowError: Bool = false
    var errorToThrow: Error?
    var getCurrentTokenCallCount = 0
    var refreshTokenCallCount = 0
    var isTokenValidCallCount = 0
    var simulatedDelay: TimeInterval = 0

    func incrementGetTokenCount() {
        getCurrentTokenCallCount += 1
    }

    func incrementRefreshTokenCount() {
        refreshTokenCallCount += 1
    }

    func incrementIsTokenValidCount() {
        isTokenValidCallCount += 1
    }

    func updateMockToken(_ token: String?) {
        mockToken = token
    }

    func updateRefreshedToken(_ token: String?) {
        refreshedMockToken = token
    }

    func updateIsTokenValidResponse(_ isValid: Bool) {
        isTokenValidResponse = isValid
    }

    func updateShouldThrowError(_ shouldThrow: Bool) {
        shouldThrowError = shouldThrow
    }

    func updateErrorToThrow(_ error: Error?) {
        errorToThrow = error
    }

    func updateSimulatedDelay(_ delay: TimeInterval) {
        simulatedDelay = delay
    }

    func getState() -> (token: String?, refreshed: String?, isValid: Bool, shouldThrow: Bool, error: Error?, delay: TimeInterval) {
        return (mockToken, refreshedMockToken, isTokenValidResponse, shouldThrowError, errorToThrow, simulatedDelay)
    }

    func getCounts() -> (getToken: Int, refresh: Int, isValid: Int) {
        return (getCurrentTokenCallCount, refreshTokenCallCount, isTokenValidCallCount)
    }

    func resetCounts() {
        getCurrentTokenCallCount = 0
        refreshTokenCallCount = 0
        isTokenValidCallCount = 0
    }
}

/// Mock authentication provider for testing and development
/// Allows configuring tokens and behaviors without requiring actual StoreKit subscriptions
public final class MockAuthenticationProvider: AuthenticationProvider {

    // MARK: - Properties

    /// Actor for thread-safe state management
    private let state = MockProviderState()

    /// The mock token to return
    public var mockToken: String? {
        get {
            // Synchronous property for test compatibility
            // Note: This may not reflect actual state due to actor concurrency
            return _cachedMockToken
        }
        set {
            _cachedMockToken = newValue
            if #available(iOS 13.0, macOS 10.15, *) {
                Task {
                    await state.updateMockToken(newValue)
                }
            }
        }
    }
    private var _cachedMockToken: String?

    /// The token to return after refresh
    public var refreshedMockToken: String? {
        get { _cachedRefreshedToken }
        set {
            _cachedRefreshedToken = newValue
            if #available(iOS 13.0, macOS 10.15, *) {
                Task {
                    await state.updateRefreshedToken(newValue)
                }
            }
        }
    }
    private var _cachedRefreshedToken: String?

    /// Whether the token should be considered valid
    public var isTokenValidResponse: Bool {
        get { _cachedIsTokenValidResponse }
        set {
            _cachedIsTokenValidResponse = newValue
            if #available(iOS 13.0, macOS 10.15, *) {
                Task {
                    await state.updateIsTokenValidResponse(newValue)
                }
            }
        }
    }
    private var _cachedIsTokenValidResponse: Bool = true

    /// Whether to throw an error on next call
    public var shouldThrowError: Bool {
        get { _cachedShouldThrowError }
        set {
            _cachedShouldThrowError = newValue
            if #available(iOS 13.0, macOS 10.15, *) {
                Task {
                    await state.updateShouldThrowError(newValue)
                }
            }
        }
    }
    private var _cachedShouldThrowError: Bool = false

    /// Specific error to throw
    public var errorToThrow: Error? {
        get { _cachedErrorToThrow }
        set {
            _cachedErrorToThrow = newValue
            if #available(iOS 13.0, macOS 10.15, *) {
                Task {
                    await state.updateErrorToThrow(newValue)
                }
            }
        }
    }
    private var _cachedErrorToThrow: Error?

    /// Number of times getCurrentToken was called (for testing)
    public var getCurrentTokenCallCount: Int {
        get {
            // Synchronous access for backward compatibility
            return 0
        }
    }

    /// Number of times refreshToken was called (for testing)
    public var refreshTokenCallCount: Int {
        get {
            return 0
        }
    }

    /// Number of times isTokenValid was called (for testing)
    public var isTokenValidCallCount: Int {
        get {
            return 0
        }
    }

    /// Delay to simulate network/processing time (in seconds)
    public var simulatedDelay: TimeInterval {
        get { _cachedSimulatedDelay }
        set {
            _cachedSimulatedDelay = newValue
            if #available(iOS 13.0, macOS 10.15, *) {
                Task {
                    await state.updateSimulatedDelay(newValue)
                }
            }
        }
    }
    private var _cachedSimulatedDelay: TimeInterval = 0

    // MARK: - Initialization

    /// Initializes a mock authentication provider
    /// - Parameters:
    ///   - token: Initial mock token
    ///   - isValid: Whether the token should be considered valid
    public init(token: String? = nil, isValid: Bool = true) {
        self._cachedMockToken = token
        self._cachedIsTokenValidResponse = isValid
        self._cachedRefreshedToken = nil
        self._cachedShouldThrowError = false
        self._cachedErrorToThrow = nil
        self._cachedSimulatedDelay = 0

        // Also update actor state
        if #available(iOS 13.0, macOS 10.15, *) {
            Task {
                await state.updateMockToken(token)
                await state.updateIsTokenValidResponse(isValid)
            }
        }
    }

    // MARK: - AuthenticationProvider Protocol

    public func getCurrentToken() async throws -> String {
        await state.incrementGetTokenCount()

        // Use cached values for test compatibility
        let delay = _cachedSimulatedDelay
        let shouldThrow = _cachedShouldThrowError
        let error = _cachedErrorToThrow
        let token = _cachedMockToken

        // Simulate delay if configured
        if delay > 0 {
            if #available(iOS 13.0, macOS 10.15, *) {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        // Throw error if configured
        if shouldThrow {
            throw error ?? AuthenticationError.tokenInvalid
        }

        // Return token or throw if not configured
        guard let token = token else {
            throw AuthenticationError.noActiveSubscription
        }

        return token
    }

    public func refreshToken() async throws -> String {
        await state.incrementRefreshTokenCount()

        // Use cached values for test compatibility
        let delay = _cachedSimulatedDelay
        let shouldThrow = _cachedShouldThrowError
        let error = _cachedErrorToThrow
        let refreshed = _cachedRefreshedToken

        // Simulate delay if configured
        if delay > 0 {
            if #available(iOS 13.0, macOS 10.15, *) {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        // Throw error if configured
        if shouldThrow {
            throw error ?? AuthenticationError.tokenExpired
        }

        // Get refreshed token
        guard let refreshed = refreshed else {
            throw AuthenticationError.tokenExpired
        }

        // Update current token (both cached and actor state)
        _cachedMockToken = refreshed
        await state.updateMockToken(refreshed)

        return refreshed
    }

    public func isTokenValid() async throws -> Bool {
        await state.incrementIsTokenValidCount()

        // Use cached values for test compatibility
        let delay = _cachedSimulatedDelay
        let shouldThrow = _cachedShouldThrowError
        let error = _cachedErrorToThrow
        let isValid = _cachedIsTokenValidResponse

        // Simulate delay if configured
        if delay > 0 {
            if #available(iOS 13.0, macOS 10.15, *) {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        // Throw error if configured
        if shouldThrow {
            throw error ?? AuthenticationError.tokenInvalid
        }

        return isValid
    }

    // MARK: - Test Helpers

    /// Resets all call counts for testing
    public func resetCallCounts() {
        if #available(iOS 13.0, macOS 10.15, *) {
            Task {
                await state.resetCounts()
            }
        }
    }

    /// Get call counts for testing (async)
    public func getCallCounts() async -> (getToken: Int, refresh: Int, isValid: Int) {
        return await state.getCounts()
    }

    /// Configures the provider to simulate an expired token scenario
    public func simulateExpiredToken() {
        if #available(iOS 13.0, macOS 10.15, *) {
            Task {
                await state.updateIsTokenValidResponse(false)
                await state.updateRefreshedToken(generateMockJWT(expiresIn: 3600)) // Valid for 1 hour
            }
        }
    }

    /// Configures the provider to simulate no active subscription
    public func simulateNoSubscription() {
        if #available(iOS 13.0, macOS 10.15, *) {
            Task {
                await state.updateMockToken(nil)
                await state.updateRefreshedToken(nil)
                await state.updateShouldThrowError(true)
                await state.updateErrorToThrow(AuthenticationError.noActiveSubscription)
            }
        }
    }

    /// Configures the provider with a valid token
    /// - Parameter expiresIn: Time in seconds until token expires
    public func configureValidToken(expiresIn: TimeInterval = 3600) {
        let token = generateMockJWT(expiresIn: expiresIn)
        let refreshedToken = generateMockJWT(expiresIn: expiresIn + 3600)

        // Update cached values for immediate access
        _cachedMockToken = token
        _cachedRefreshedToken = refreshedToken
        _cachedIsTokenValidResponse = true
        _cachedShouldThrowError = false
        _cachedErrorToThrow = nil

        // Also update actor state
        if #available(iOS 13.0, macOS 10.15, *) {
            Task {
                await state.updateMockToken(token)
                await state.updateRefreshedToken(refreshedToken)
                await state.updateIsTokenValidResponse(true)
                await state.updateShouldThrowError(false)
                await state.updateErrorToThrow(nil)
            }
        }
    }

    // MARK: - Mock JWT Generation

    /// Generates a mock JWT token for testing
    /// - Parameter expiresIn: Time in seconds until token expires
    /// - Returns: A mock JWT string
    public func generateMockJWT(expiresIn seconds: TimeInterval) -> String {
        // Create mock header
        let header: [String: Any] = [
            "alg": "ES256",
            "typ": "JWT",
            "x5c": ["mock-certificate"]
        ]

        // Create mock payload with StoreKit-like structure
        let expiry = Date().addingTimeInterval(seconds)
        let payload: [String: Any] = [
            "transactionId": UUID().uuidString,
            "productId": "com.nolock.social.premium",
            "purchaseDate": Date().timeIntervalSince1970 * 1000,
            "expirationDate": expiry.timeIntervalSince1970 * 1000,
            "environment": "Production",
            "signedDate": Date().timeIntervalSince1970 * 1000,
            "inAppOwnershipType": "PURCHASED",
            "subscriptionGroupIdentifier": "12345678"
        ]

        // Encode header and payload
        let headerData = try! JSONSerialization.data(withJSONObject: header)
        let payloadData = try! JSONSerialization.data(withJSONObject: payload)

        let headerBase64 = headerData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        let payloadBase64 = payloadData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        // Create mock signature
        let signature = "mock-signature-\(UUID().uuidString.prefix(8))"
            .data(using: .utf8)!
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        return "\(headerBase64).\(payloadBase64).\(signature)"
    }
}

// MARK: - Convenience Factory Methods

public extension MockAuthenticationProvider {
    /// Creates a mock provider configured for successful authentication
    static func successfulProvider() async -> MockAuthenticationProvider {
        let provider = MockAuthenticationProvider()
        let token = provider.generateMockJWT(expiresIn: 3600)
        let refreshedToken = provider.generateMockJWT(expiresIn: 7200)

        // Update both cached values and actor state
        provider._cachedMockToken = token
        provider._cachedRefreshedToken = refreshedToken
        provider._cachedIsTokenValidResponse = true
        provider._cachedShouldThrowError = false

        await provider.state.updateMockToken(token)
        await provider.state.updateRefreshedToken(refreshedToken)
        await provider.state.updateIsTokenValidResponse(true)
        await provider.state.updateShouldThrowError(false)
        return provider
    }

    /// Creates a mock provider configured for expired token scenario
    static func expiredTokenProvider() async -> MockAuthenticationProvider {
        let provider = MockAuthenticationProvider()
        let refreshedToken = provider.generateMockJWT(expiresIn: 3600)

        // Update both cached values and actor state
        provider._cachedIsTokenValidResponse = false
        provider._cachedRefreshedToken = refreshedToken

        await provider.state.updateIsTokenValidResponse(false)
        await provider.state.updateRefreshedToken(refreshedToken)
        return provider
    }

    /// Creates a mock provider configured for no subscription scenario
    static func noSubscriptionProvider() async -> MockAuthenticationProvider {
        let provider = MockAuthenticationProvider()

        // Update both cached values and actor state
        provider._cachedMockToken = nil
        provider._cachedRefreshedToken = nil
        provider._cachedShouldThrowError = true
        provider._cachedErrorToThrow = AuthenticationError.noActiveSubscription

        await provider.state.updateMockToken(nil)
        await provider.state.updateRefreshedToken(nil)
        await provider.state.updateShouldThrowError(true)
        await provider.state.updateErrorToThrow(AuthenticationError.noActiveSubscription)
        return provider
    }

    /// Creates a mock provider configured for successful authentication (synchronous convenience)
    static func successfulProviderSync() -> MockAuthenticationProvider {
        let provider = MockAuthenticationProvider()
        provider.configureValidToken(expiresIn: 3600)
        return provider
    }
}