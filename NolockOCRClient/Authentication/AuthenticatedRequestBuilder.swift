import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Factory for creating authenticated request builders
public class AuthenticatedRequestBuilderFactory: RequestBuilderFactory {

    // MARK: - Properties

    /// The authentication provider for token management
    private let authProvider: AuthenticationProvider

    /// Configuration for authentication behavior
    private let configuration: AuthenticationConfiguration

    // MARK: - Public Accessors for Testing

    /// The current authentication provider (for testing)
    public var provider: AuthenticationProvider {
        return authProvider
    }

    /// The current authentication configuration (for testing)
    public var authConfiguration: AuthenticationConfiguration {
        return configuration
    }

    // MARK: - Initialization

    /// Initializes the authenticated request builder factory
    /// - Parameters:
    ///   - authProvider: The authentication provider
    ///   - configuration: Authentication configuration
    public init(authProvider: AuthenticationProvider,
                configuration: AuthenticationConfiguration = .default) {
        self.authProvider = authProvider
        self.configuration = configuration
    }

    // MARK: - RequestBuilderFactory Protocol

    public func getNonDecodableBuilder<T>() -> RequestBuilder<T>.Type {
        return AuthenticatedURLSessionRequestBuilder<T>.self
    }

    public func getBuilder<T: Decodable>() -> RequestBuilder<T>.Type {
        return AuthenticatedURLSessionDecodableRequestBuilder<T>.self
    }
}

/// Authenticated version of URLSessionRequestBuilder that injects authorization headers
open class AuthenticatedURLSessionRequestBuilder<T>: URLSessionRequestBuilder<T> {

    // MARK: - Properties

    /// Shared authentication manager instance
    private var authManager: AuthenticationManager {
        return AuthenticationManager.shared
    }

    /// Public accessor for the authentication manager (for testing)
    public var authenticationManager: AuthenticationManager {
        return authManager
    }

    // MARK: - Overrides

    override open func execute(_ apiResponseQueue: DispatchQueue = NolockOCRClientAPI.apiResponseQueue,
                              _ completion: @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void) -> RequestTask {

        // Always fetch and add authentication token
        let requestTask = RequestTask()

        if #available(iOS 13.0, macOS 10.15, *) {
            Task {
            do {
                // Get fresh token
                let token = try await authManager.getToken()

                // Update headers with token
                var updatedHeaders = headers
                updatedHeaders["Authorization"] = "Bearer \(token)"

                // Create new request builder with updated headers
                let authenticatedBuilder = AuthenticatedURLSessionRequestBuilder<T>(
                    method: method,
                    URLString: URLString,
                    parameters: parameters,
                    headers: updatedHeaders
                )

                // Execute the authenticated request
                _ = authenticatedBuilder.executeWithRetry(apiResponseQueue, completion)

            } catch {
                // Execute anyway to get the actual server error response
                _ = super.execute(apiResponseQueue, completion)
            }
        }
        } else {
            // Fallback for older OS versions
            _ = super.execute(apiResponseQueue, completion)
        }

        return requestTask
    }

    /// Executes the request with retry logic for 401 responses
    private func executeWithRetry(_ apiResponseQueue: DispatchQueue = NolockOCRClientAPI.apiResponseQueue,
                                  _ completion: @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void) -> RequestTask {

        return super.execute(apiResponseQueue) { [weak self] result in
            guard let self = self else {
                completion(result)
                return
            }

            switch result {
            case .failure(let errorResponse):
                // Check if it's a 401 Unauthorized
                if case .error(let statusCode, _, _, _) = errorResponse,
                   statusCode == 401 {
                    // Attempt token refresh
                    if #available(iOS 13.0, macOS 10.15, *) {
                        Task {
                        do {
                            // Refresh the token
                            let newToken = try await self.authManager.refreshToken()

                            // Update headers with new token
                            var updatedHeaders = self.headers
                            updatedHeaders["Authorization"] = "Bearer \(newToken)"

                            // Create new request with refreshed token
                            let retryBuilder = AuthenticatedURLSessionRequestBuilder<T>(
                                method: self.method,
                                URLString: self.URLString,
                                parameters: self.parameters,
                                headers: updatedHeaders
                            )

                            // Execute retry (without further retry to avoid infinite loop)
                            _ = retryBuilder.executeWithRetry(apiResponseQueue, completion)

                        } catch {
                            // Token refresh failed, return original 401 error with server's response
                            apiResponseQueue.async {
                                completion(result)
                            }
                        }
                    }
                    } else {
                        // Fallback for older OS versions
                        completion(result)
                    }
                } else {
                    // Not a 401 or doesn't require auth, pass through
                    completion(result)
                }

            case .success:
                // Success, pass through
                completion(result)
            }
        }
    }
}

/// Authenticated version of URLSessionDecodableRequestBuilder
open class AuthenticatedURLSessionDecodableRequestBuilder<T: Decodable>: AuthenticatedURLSessionRequestBuilder<T> {
    // Inherits all authentication behavior from parent class
    // Decodable-specific logic is handled by URLSessionDecodableRequestBuilder
}

/// Singleton manager for authentication state
public class AuthenticationManager {

    // MARK: - Singleton

    public static let shared = AuthenticationManager()

    // MARK: - Properties

    /// The current authentication provider
    private var authProvider: AuthenticationProvider?

    /// Configuration for authentication
    private var configuration: AuthenticationConfiguration

    /// Lock for thread-safe access
    private let lock = NSLock()

    // MARK: - Initialization

    private init() {
        self.configuration = .default
    }

    // MARK: - Configuration

    /// Configures the authentication manager
    /// - Parameters:
    ///   - provider: The authentication provider to use
    ///   - configuration: Authentication configuration
    public func configure(provider: AuthenticationProvider,
                         configuration: AuthenticationConfiguration = .default) {
        lock.lock()
        defer { lock.unlock() }

        self.authProvider = provider
        self.configuration = configuration
    }

    /// The current authentication provider (for testing)
    public var provider: AuthenticationProvider? {
        lock.lock()
        defer { lock.unlock() }
        return authProvider
    }

    // MARK: - Token Management

    /// Gets a valid authentication token
    /// - Returns: A valid authentication token
    /// - Throws: AuthenticationError if token cannot be obtained
    public func getToken() async throws -> String {
        // Get provider
        guard let provider = authProvider else {
            throw AuthenticationError.configurationError("No authentication provider configured")
        }

        // Check if current token is valid
        let isValid = try await provider.isTokenValid()

        let token: String
        if isValid {
            // Get current token
            token = try await provider.getCurrentToken()
        } else if configuration.automaticTokenRefresh {
            // Refresh token
            token = try await provider.refreshToken()
        } else {
            // Manual refresh required
            throw AuthenticationError.tokenExpired
        }

        return token
    }

    /// Refreshes the authentication token
    /// - Returns: The new authentication token
    /// - Throws: AuthenticationError if token cannot be refreshed
    public func refreshToken() async throws -> String {
        guard let provider = authProvider else {
            throw AuthenticationError.configurationError("No authentication provider configured")
        }

        return try await provider.refreshToken()
    }

}