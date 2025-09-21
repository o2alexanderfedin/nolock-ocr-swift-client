import Foundation
#if canImport(StoreKit)
import StoreKit
#endif

/// StoreKit 2 based authentication provider that extracts JWS tokens from active subscriptions
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public final class StoreKitAuthenticationProvider: AuthenticationProvider {

    // MARK: - Properties

    /// Configuration for the authentication provider
    public let configuration: AuthenticationConfiguration

    /// Product identifiers to check for active subscriptions (optional)
    /// If nil, will check all subscriptions
    public let productIdentifiers: Set<String>?

    // MARK: - Initialization

    /// Initializes the StoreKit authentication provider
    /// - Parameters:
    ///   - configuration: Authentication configuration
    ///   - productIdentifiers: Optional set of product IDs to check. If nil, checks all subscriptions
    public init(
        configuration: AuthenticationConfiguration = .default,
        productIdentifiers: Set<String>? = nil
    ) {
        self.configuration = configuration
        self.productIdentifiers = productIdentifiers
    }

    // MARK: - AuthenticationProvider Protocol

    public func getCurrentToken() async throws -> String {
        return try await fetchTokenFromStoreKit()
    }

    public func refreshToken() async throws -> String {
        return try await fetchTokenFromStoreKit()
    }

    public func isTokenValid() async throws -> Bool {
        do {
            _ = try await fetchTokenFromStoreKit()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Private Methods

    private func fetchTokenFromStoreKit() async throws -> String {
        #if canImport(StoreKit)
        var foundTransaction: Transaction?
        var foundJWS: String?

        // Iterate through current entitlements to find active subscription
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                // Check if this is a subscription transaction
                guard transaction.productType == .autoRenewable ||
                      transaction.productType == .nonRenewable else {
                    continue
                }

                // If product identifiers are specified, check if this transaction matches
                if let productIds = productIdentifiers,
                   !productIds.contains(transaction.productID) {
                    continue
                }

                // Check if the transaction is not expired
                if let expirationDate = transaction.expirationDate,
                   expirationDate > Date() {
                    foundTransaction = transaction
                    foundJWS = result.jwsRepresentation
                    break
                }

            case .unverified(let transaction, let error):
                // Log unverified transaction for debugging
                print("Unverified transaction for product \(transaction.productID): \(error)")
                continue
            }
        }

        // Check if we found an active subscription
        guard let transaction = foundTransaction,
              let jws = foundJWS else {
            throw AuthenticationError.noActiveSubscription
        }

        return jws
        #else
        throw AuthenticationError.configurationError("StoreKit is not available on this platform")
        #endif
    }

    // MARK: - Token Parsing Utilities

    /// Extracts the expiration date from a JWS token payload
    /// - Parameter jws: The JWS token string
    /// - Returns: The expiration date if found, nil otherwise
    private func extractExpirationFromJWS(_ jws: String) -> Date? {
        let components = jws.split(separator: ".")
        guard components.count == 3 else { return nil }

        let payload = String(components[1])
        guard let payloadData = base64URLDecode(payload) else { return nil }

        do {
            if let json = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
               let exp = json["expirationDate"] as? TimeInterval {
                return Date(timeIntervalSince1970: exp / 1000) // Convert from milliseconds
            }
        } catch {
            print("Failed to parse JWS payload: \(error)")
        }

        return nil
    }

    /// Decodes a base64URL encoded string
    /// - Parameter base64URL: The base64URL encoded string
    /// - Returns: The decoded data if successful, nil otherwise
    private func base64URLDecode(_ base64URL: String) -> Data? {
        var base64 = base64URL
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if necessary
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        return Data(base64Encoded: base64)
    }
}

// MARK: - Transaction Type Extension

#if canImport(StoreKit)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Transaction {
    /// Determines the product type of the transaction
    var productType: ProductType {
        // StoreKit 2 provides product type information
        // This is a simplified categorization based on transaction properties
        if self.productID.contains("subscription") ||
           self.expirationDate != nil {
            return .autoRenewable
        } else if self.productID.contains("nonrenewing") {
            return .nonRenewable
        } else {
            return .nonConsumable
        }
    }
}

/// Product type enumeration for transaction categorization
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum ProductType {
    case consumable
    case nonConsumable
    case autoRenewable
    case nonRenewable
}
#endif