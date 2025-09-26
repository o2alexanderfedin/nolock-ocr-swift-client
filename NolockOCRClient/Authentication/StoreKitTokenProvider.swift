import Foundation
#if canImport(StoreKit)
import StoreKit
#endif

/// Provides JWS tokens from StoreKit purchases for OCR server authentication
@available(iOS 15.0, macOS 12.0, *)
public struct StoreKitTokenProvider: TokenProvider {
    private let tokenKey = "latestTransactionJWS"

    public init() {}

    public func getToken() async throws -> String {
        // First, check for stored JWS token from recent purchase
        if let storedToken = UserDefaults.standard.string(forKey: tokenKey),
           !storedToken.isEmpty {
            print("🔐 Using stored JWS token for authentication")
            return storedToken
        }

        #if canImport(StoreKit)
        // Fall back to checking current entitlements
        print("🔍 Checking current StoreKit entitlements...")

        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                // Check if transaction is still valid (not expired)
                if let expirationDate = transaction.expirationDate,
                   expirationDate > Date() {
                    let jwsToken = result.jwsRepresentation

                    // Store the token for future use
                    UserDefaults.standard.set(jwsToken, forKey: tokenKey)
                    print("✅ Found valid entitlement, JWS token retrieved and stored")

                    return jwsToken
                }
            case .unverified(let transaction, let error):
                print("⚠️ Unverified transaction: \(transaction.id), error: \(error)")
                continue
            }
        }
        #endif

        // No valid token found
        print("❌ No valid JWS token found")
        return UUID.zeroString
    }
}

/*
@available(iOS 15.0, macOS 12.0, *)
public struct StoreKitTokenProvider: TokenProvider {
    public init() {}

    public func getToken() async throws -> String {
        #if canImport(StoreKit)
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.expirationDate ?? Date() > Date() {
                return result.jwsRepresentation
            }
        }
        #endif

        return UUID.zeroString
    }
}
*/