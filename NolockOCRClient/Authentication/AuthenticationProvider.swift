import Foundation

/// Protocol defining the contract for authentication token providers
/// This allows for different implementations (StoreKit, Mock, Custom) while maintaining a consistent interface
public protocol AuthenticationProvider {
    /// Retrieves the current authentication token
    /// - Returns: The JWS token string for authorization
    /// - Throws: AuthenticationError if token cannot be retrieved
    func getCurrentToken() async throws -> String

    /// Refreshes the authentication token
    /// - Returns: The new JWS token string
    /// - Throws: AuthenticationError if token cannot be refreshed
    func refreshToken() async throws -> String

    /// Checks if the current token is still valid
    /// - Returns: true if the token is valid, false otherwise
    func isTokenValid() async throws -> Bool
}

/// Errors that can occur during authentication
public enum AuthenticationError: LocalizedError, Equatable {
    case noActiveSubscription
    case tokenExpired
    case tokenInvalid
    case networkError(Error)
    case storeKitError(String)
    case configurationError(String)

    public var errorDescription: String? {
        switch self {
        case .noActiveSubscription:
            return "No active subscription found. Please ensure you have an active subscription."
        case .tokenExpired:
            return "Authentication token has expired. Please refresh your authentication."
        case .tokenInvalid:
            return "Authentication token is invalid or malformed."
        case .networkError(let error):
            return "Network error occurred: \(error.localizedDescription)"
        case .storeKitError(let message):
            return "StoreKit error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }

    public static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
        switch (lhs, rhs) {
        case (.noActiveSubscription, .noActiveSubscription),
             (.tokenExpired, .tokenExpired),
             (.tokenInvalid, .tokenInvalid):
            return true
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return (lhsError as NSError) == (rhsError as NSError)
        case (.storeKitError(let lhsMessage), .storeKitError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.configurationError(let lhsMessage), .configurationError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

/// Configuration for the authentication system
public struct AuthenticationConfiguration {
    /// Whether to automatically refresh expired tokens
    public var automaticTokenRefresh: Bool

    /// Time interval before token expiration to trigger refresh (in seconds)
    public var tokenRefreshBuffer: TimeInterval

    /// Maximum number of retry attempts for token refresh
    public var maxRetryAttempts: Int

    /// Retry delay between attempts (in seconds)
    public var retryDelay: TimeInterval

    // MARK: - Test API Compatibility Properties

    /// Whether authentication is required (alias for automaticTokenRefresh)
    public var requiresAuthentication: Bool {
        get { automaticTokenRefresh }
        set { automaticTokenRefresh = newValue }
    }

    /// Refresh threshold in seconds (alias for tokenRefreshBuffer)
    public var refreshThreshold: TimeInterval {
        get { tokenRefreshBuffer }
        set { tokenRefreshBuffer = newValue }
    }

    /// Default configuration
    public static var `default`: AuthenticationConfiguration {
        return AuthenticationConfiguration(
            automaticTokenRefresh: true,
            tokenRefreshBuffer: 300, // 5 minutes before expiration
            maxRetryAttempts: 3,
            retryDelay: 1.0
        )
    }

    public init(
        automaticTokenRefresh: Bool = true,
        tokenRefreshBuffer: TimeInterval = 300,
        maxRetryAttempts: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) {
        self.automaticTokenRefresh = automaticTokenRefresh
        self.tokenRefreshBuffer = tokenRefreshBuffer
        self.maxRetryAttempts = maxRetryAttempts
        self.retryDelay = retryDelay
    }

    /// Convenience initializer for test compatibility
    public init(
        requiresAuthentication: Bool,
        refreshThreshold: TimeInterval,
        maxRetryAttempts: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) {
        self.automaticTokenRefresh = requiresAuthentication
        self.tokenRefreshBuffer = refreshThreshold
        self.maxRetryAttempts = maxRetryAttempts
        self.retryDelay = retryDelay
    }
}