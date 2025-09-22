import Foundation
#if canImport(StoreKit)
import StoreKit
#endif

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
        throw NSError(domain: "NoToken", code: 0)
        #else
        throw NSError(domain: "StoreKitUnavailable", code: 0)
        #endif
    }
}