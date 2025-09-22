import Foundation

/// Simple protocol for providing authentication tokens
public protocol AuthenticationProvider {
    /// Gets the authentication token
    /// - Returns: The JWS token string for authorization
    /// - Throws: AuthenticationError if token cannot be retrieved
    func getToken() async throws -> String
}

/// Errors that can occur during authentication
public enum AuthenticationError: LocalizedError, Equatable {
    case noActiveSubscription
    case tokenExpired
    case tokenInvalid
    case networkError(Error)
    case configurationError(String)

    public var errorDescription: String? {
        switch self {
        case .noActiveSubscription:
            return "No active subscription found"
        case .tokenExpired:
            return "Authentication token has expired"
        case .tokenInvalid:
            return "Authentication token is invalid"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
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
        case (.configurationError(let lhsMessage), .configurationError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

/// Configuration for the authentication system (kept for compatibility)
public struct AuthenticationConfiguration {
    public var automaticTokenRefresh: Bool = false
    public var tokenRefreshBuffer: TimeInterval = 300
    public var maxRetryAttempts: Int = 3
    public var retryDelay: TimeInterval = 1.0

    public static var `default` = AuthenticationConfiguration()

    public init() {}
}