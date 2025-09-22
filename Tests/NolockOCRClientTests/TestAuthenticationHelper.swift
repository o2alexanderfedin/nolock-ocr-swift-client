import Foundation
#if canImport(StoreKit)
import StoreKit
#endif
@testable import NolockOCRClient

/// Minimal helper for authentication testing
class TestAuthenticationHelper {

    /// Check if a real authentication token is available from StoreKit
    static func canProvideAuthenticationToken() async -> Bool {
        #if canImport(StoreKit)
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            do {
                let provider = StoreKitTokenProvider()
                _ = try await provider.getToken()
                return true
            } catch {
                // No valid StoreKit token available
                return false
            }
        }
        #endif
        return false
    }

    /// Determine if tests should expect success or error
    static func shouldExpectSuccess() async -> Bool {
        return await canProvideAuthenticationToken()
    }
}