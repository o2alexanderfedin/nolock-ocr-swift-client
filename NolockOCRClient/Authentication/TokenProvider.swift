import Foundation

public protocol TokenProvider {
    func getToken() async throws -> String
}