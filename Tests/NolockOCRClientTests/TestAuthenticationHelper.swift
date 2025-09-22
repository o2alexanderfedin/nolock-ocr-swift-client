import Foundation
import XCTest
#if canImport(StoreKit)
import StoreKit
#endif
@testable import NolockOCRClient

/// Helper class for managing authentication in tests
class TestAuthenticationHelper {

    /// Check if a real authentication token is available
    /// Returns the token if available, nil otherwise
    static func getRealAuthenticationToken() async -> String? {
        // Check environment variable first
        if let envToken = ProcessInfo.processInfo.environment["NOLOCK_TEST_AUTH_TOKEN"] {
            return envToken
        }

        #if canImport(StoreKit)
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            // Try to get a real StoreKit token
            do {
                let provider = StoreKitTokenProvider()
                return try await provider.getToken()
            } catch {
                // No valid StoreKit token available
            }
        }
        #endif

        return nil
    }

    /// Configure authentication for tests
    /// Uses real token if available, mock token otherwise
    static func configureTestAuthentication() async -> (isReal: Bool, token: String) {
        if let realToken = await getRealAuthenticationToken() {
            // Use real authentication
            #if canImport(StoreKit)
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                NolockOCRClientAPI.configureAuthentication(provider: StoreKitTokenProvider())
            }
            #endif
            return (isReal: true, token: realToken)
        } else {
            // Use mock authentication
            let mockToken = "mock-test-token-\(UUID().uuidString)"
            NolockOCRClientAPI.configureAuthentication(provider: MockTokenProvider())
            return (isReal: false, token: mockToken)
        }
    }

    /// Helper to assert API response based on authentication state
    static func assertAPIResponse<T>(
        _ result: Result<T, Error>,
        isRealAuth: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        switch result {
        case .success:
            if !isRealAuth {
                XCTFail("Expected 401 error with mock auth, but request succeeded", file: file, line: line)
            }
            // Success with real auth is expected

        case .failure(let error):
            if isRealAuth {
                XCTFail("Expected success with real auth, but got error: \(error)", file: file, line: line)
            } else {
                // Check if it's a 401 error
                if let errorResponse = error as? ErrorResponse {
                    switch errorResponse {
                    case .error(let code, _, _, _):
                        // Accept 401 (unauthorized), 502 (bad gateway), or 503 (service unavailable)
                        let acceptableErrors = [401, 502, 503]
                        XCTAssertTrue(acceptableErrors.contains(code),
                                     "Expected 401/502/503 with mock auth, got \(code)", file: file, line: line)
                    }
                } else {
                    XCTFail("Expected 401 ErrorResponse, got: \(error)", file: file, line: line)
                }
            }
        }
    }

    /// Helper to handle async API calls with proper authentication expectations
    static func performAuthenticatedAPICall<T>(
        apiCall: () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let (isReal, _) = await configureTestAuthentication()

        do {
            let result = try await apiCall()
            if !isReal {
                XCTFail("Expected 401 error with mock auth, but request succeeded with result: \(result)", file: file, line: line)
            }
            // Success with real auth is expected
        } catch {
            if isReal {
                XCTFail("Expected success with real auth, but got error: \(error)", file: file, line: line)
            } else {
                // Verify it's a 401 error
                if let errorResponse = error as? ErrorResponse {
                    switch errorResponse {
                    case .error(let code, _, _, _):
                        // Accept 401 (unauthorized), 502 (bad gateway), or 503 (service unavailable)
                        let acceptableErrors = [401, 502, 503]
                        XCTAssertTrue(acceptableErrors.contains(code),
                                     "Expected 401/502/503 with mock auth, got \(code)", file: file, line: line)
                    }
                } else {
                    XCTFail("Expected 401 ErrorResponse, got: \(error)", file: file, line: line)
                }
            }
        }
    }
}