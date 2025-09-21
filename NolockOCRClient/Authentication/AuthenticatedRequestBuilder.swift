import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Storage for the current authentication context
public struct AuthenticationContext {
    /// The current authentication provider
    public static var provider: AuthenticationProvider?

    /// The current authentication configuration
    public static var configuration: AuthenticationConfiguration = .default

    /// Configure the authentication context
    public static func configure(provider: AuthenticationProvider,
                                 configuration: AuthenticationConfiguration = .default) {
        self.provider = provider
        self.configuration = configuration
    }

    /// Reset to defaults
    public static func reset() {
        provider = nil
        configuration = .default
    }
}

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

        // Set the global context for the builders
        AuthenticationContext.configure(provider: authProvider, configuration: configuration)
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

    /// The authentication provider (from context or injected)
    private var authProvider: AuthenticationProvider? {
        return AuthenticationContext.provider
    }

    /// Configuration for authentication (from context)
    private var configuration: AuthenticationConfiguration {
        return AuthenticationContext.configuration
    }

    // MARK: - Overrides

    override open func execute(_ apiResponseQueue: DispatchQueue = NolockOCRClientAPI.apiResponseQueue,
                              _ completion: @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void) -> RequestTask {

        let requestTask = RequestTask()

        // Check if we have an auth provider
        guard let provider = authProvider else {
            // No auth provider, execute without authentication
            return super.execute(apiResponseQueue, completion)
        }

        if #available(iOS 13.0, macOS 10.15, *) {
            Task {
                await executeWithAuth(provider: provider, apiResponseQueue, completion)
            }
        } else {
            // Fallback for older OS versions - no authentication
            _ = super.execute(apiResponseQueue, completion)
        }

        return requestTask
    }

    // MARK: - Private Methods

    /// Executes the request with authentication
    @available(iOS 13.0, macOS 10.15, *)
    private func executeWithAuth(provider: AuthenticationProvider,
                                 _ apiResponseQueue: DispatchQueue,
                                 _ completion: @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void) async {
        do {
            // Get token directly from provider
            let token = try await getValidToken(from: provider)

            // Update headers with token
            var updatedHeaders = headers
            updatedHeaders["Authorization"] = "Bearer \(token)"

            // Create new builder with auth headers
            let authenticatedBuilder = AuthenticatedURLSessionRequestBuilder<T>(
                method: method,
                URLString: URLString,
                parameters: parameters,
                headers: updatedHeaders
            )

            // Execute request with retry logic for 401
            authenticatedBuilder.executeWithRetry(provider: provider,
                                                 apiResponseQueue,
                                                 completion,
                                                 retryCount: 0)

        } catch {
            // If we can't get a token, execute anyway to get server error
            _ = super.execute(apiResponseQueue, completion)
        }
    }

    /// Gets a valid token, refreshing if needed
    @available(iOS 13.0, macOS 10.15, *)
    private func getValidToken(from provider: AuthenticationProvider) async throws -> String {
        // Check if current token is valid
        let isValid = try await provider.isTokenValid()

        if isValid {
            return try await provider.getCurrentToken()
        } else if configuration.automaticTokenRefresh {
            return try await provider.refreshToken()
        } else {
            throw AuthenticationError.tokenExpired
        }
    }

    /// Executes the request with retry logic for 401 responses
    private func executeWithRetry(provider: AuthenticationProvider,
                                  _ apiResponseQueue: DispatchQueue,
                                  _ completion: @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void,
                                  retryCount: Int) {

        super.execute(apiResponseQueue) { [weak self] result in
            guard let self = self else {
                completion(result)
                return
            }

            switch result {
            case .failure(let errorResponse):
                // Check if it's a 401 Unauthorized and we haven't exceeded retry attempts
                if case .error(let statusCode, _, _, _) = errorResponse,
                   statusCode == 401,
                   retryCount < self.configuration.maxRetryAttempts {

                    // Attempt token refresh
                    if #available(iOS 13.0, macOS 10.15, *) {
                        Task {
                            do {
                                // Refresh the token directly
                                let newToken = try await provider.refreshToken()

                                // Update headers with new token
                                var updatedHeaders = self.headers
                                updatedHeaders["Authorization"] = "Bearer \(newToken)"

                                // Create new builder with refreshed token
                                let retryBuilder = AuthenticatedURLSessionRequestBuilder<T>(
                                    method: self.method,
                                    URLString: self.URLString,
                                    parameters: self.parameters,
                                    headers: updatedHeaders
                                )

                                // Retry request with new token
                                retryBuilder.executeWithRetry(provider: provider,
                                                             apiResponseQueue,
                                                             completion,
                                                             retryCount: retryCount + 1)

                            } catch {
                                // Token refresh failed, return original 401 error
                                apiResponseQueue.async {
                                    completion(result)
                                }
                            }
                        }
                    } else {
                        // No async/await support, can't refresh
                        completion(result)
                    }
                } else {
                    // Not a 401, max retries exceeded, or no auth required
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