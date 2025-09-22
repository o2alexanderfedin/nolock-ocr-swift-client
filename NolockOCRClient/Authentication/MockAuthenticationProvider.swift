import Foundation

/// Dead simple mock authentication provider for testing
public final class MockAuthenticationProvider: AuthenticationProvider {

    private var token: String

    /// Set to true to make getToken throw an error
    public var shouldThrow = false

    /// Error to throw when shouldThrow is true
    public var errorToThrow: Error = AuthenticationError.tokenExpired

    public init(token: String) {
        self.token = token
    }

    public func getToken() async throws -> String {
        if shouldThrow {
            throw errorToThrow
        }
        return token
    }
}

// MARK: - Convenience factory methods for common test scenarios

extension MockAuthenticationProvider {

    /// Creates a mock provider that always succeeds
    public static func alwaysSucceeds(token: String = "test-token") -> MockAuthenticationProvider {
        return MockAuthenticationProvider(token: token)
    }

    /// Creates a mock provider that always fails
    public static func alwaysFails(error: Error = AuthenticationError.tokenExpired) -> MockAuthenticationProvider {
        let provider = MockAuthenticationProvider(token: "failing-token")
        provider.shouldThrow = true
        provider.errorToThrow = error
        return provider
    }
}