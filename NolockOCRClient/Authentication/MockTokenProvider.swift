import Foundation

public struct MockTokenProvider: TokenProvider {
    public init() {}

    public func getToken() async throws -> String {
        return UUID().uuidString
    }
}