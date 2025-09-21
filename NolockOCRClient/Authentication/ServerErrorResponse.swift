//
//  ServerErrorResponse.swift
//  NolockOCRClient
//
//  Error response wrapper for API error messages
//

import Foundation

/// Server error response structure for 401 and other error responses
public struct ServerErrorResponse: Codable, Error {
    /// The error message from the server
    public let error: String

    /// Optional error code
    public let code: String?

    /// Optional additional details
    public let details: String?

    /// Computed property for display message
    public var message: String {
        return error
    }

    /// Initialize with just an error message
    public init(error: String, code: String? = nil, details: String? = nil) {
        self.error = error
        self.code = code
        self.details = details
    }

    /// Try to decode from data, returns nil if not valid error format
    public static func from(data: Data?) -> ServerErrorResponse? {
        guard let data = data else { return nil }

        let decoder = JSONDecoder()

        // Try to decode as ServerErrorResponse
        if let errorResponse = try? decoder.decode(ServerErrorResponse.self, from: data) {
            return errorResponse
        }

        // Try to decode as simple dictionary with "error" key
        if let dict = try? decoder.decode([String: String].self, from: data),
           let errorMessage = dict["error"] {
            return ServerErrorResponse(error: errorMessage)
        }

        // Try to decode as dictionary with "message" key (alternative format)
        if let dict = try? decoder.decode([String: String].self, from: data),
           let message = dict["message"] {
            return ServerErrorResponse(error: message)
        }

        return nil
    }
}

// MARK: - LocalizedError conformance
extension ServerErrorResponse: LocalizedError {
    public var errorDescription: String? {
        return error
    }

    public var failureReason: String? {
        return code
    }

    public var helpAnchor: String? {
        return details
    }
}