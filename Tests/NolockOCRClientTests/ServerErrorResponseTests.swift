//
//  ServerErrorResponseTests.swift
//  NolockOCRClientTests
//
//  Tests for server error response handling
//

import XCTest
import Foundation
@testable import NolockOCRClient

final class ServerErrorResponseTests: XCTestCase {

    // MARK: - JSON Parsing Tests

    func testParseSimpleErrorFormat() {
        // Given: Simple {"error": "message"} format
        let json = """
        {"error": "Invalid authentication token"}
        """
        let data = json.data(using: .utf8)!

        // When: Parsing the error
        let errorResponse = ServerErrorResponse.from(data: data)

        // Then: Should extract the error message
        XCTAssertNotNil(errorResponse)
        XCTAssertEqual(errorResponse?.error, "Invalid authentication token")
        XCTAssertEqual(errorResponse?.message, "Invalid authentication token")
    }

    func testParseMessageFormat() {
        // Given: {"message": "error text"} format
        let json = """
        {"message": "Unauthorized access"}
        """
        let data = json.data(using: .utf8)!

        // When: Parsing the error
        let errorResponse = ServerErrorResponse.from(data: data)

        // Then: Should extract the message
        XCTAssertNotNil(errorResponse)
        XCTAssertEqual(errorResponse?.error, "Unauthorized access")
    }

    func testParseComplexErrorFormat() {
        // Given: Complex error with code and details
        let json = """
        {"error": "Token expired", "code": "AUTH_001", "details": "Please refresh your token"}
        """
        let data = json.data(using: .utf8)!

        // When: Parsing the error
        let errorResponse = ServerErrorResponse.from(data: data)

        // Then: Should extract all fields
        XCTAssertNotNil(errorResponse)
        XCTAssertEqual(errorResponse?.error, "Token expired")
        XCTAssertEqual(errorResponse?.code, "AUTH_001")
        XCTAssertEqual(errorResponse?.details, "Please refresh your token")
    }

    func testParseInvalidJSON() {
        // Given: Invalid JSON
        let data = "not json".data(using: .utf8)!

        // When: Parsing the error
        let errorResponse = ServerErrorResponse.from(data: data)

        // Then: Should return nil
        XCTAssertNil(errorResponse)
    }

    func testParseEmptyData() {
        // Given: Empty data
        let data: Data? = nil

        // When: Parsing the error
        let errorResponse = ServerErrorResponse.from(data: data)

        // Then: Should return nil
        XCTAssertNil(errorResponse)
    }

    func testParseUnexpectedFormat() {
        // Given: JSON without error or message keys
        let json = """
        {"status": "failed", "reason": "unknown"}
        """
        let data = json.data(using: .utf8)!

        // When: Parsing the error
        let errorResponse = ServerErrorResponse.from(data: data)

        // Then: Should return nil
        XCTAssertNil(errorResponse)
    }

    // MARK: - LocalizedError Tests

    func testLocalizedErrorDescription() {
        // Given: Error response
        let errorResponse = ServerErrorResponse(
            error: "Authentication failed",
            code: "AUTH_FAIL",
            details: "Check your credentials"
        )

        // Then: LocalizedError properties should be set
        XCTAssertEqual(errorResponse.errorDescription, "Authentication failed")
        XCTAssertEqual(errorResponse.failureReason, "AUTH_FAIL")
        XCTAssertEqual(errorResponse.helpAnchor, "Check your credentials")
    }

    // MARK: - Integration with ErrorResponse

    func testErrorResponseWithServerError() async throws {
        // Given: A 401 response with error JSON
        let json = """
        {"error": "Invalid authentication token"}
        """
        let data = json.data(using: .utf8)!

        // When: Creating an ErrorResponse
        let serverError = ServerErrorResponse.from(data: data)!
        let errorResponse = ErrorResponse.error(401, data, nil, serverError)

        // Then: Should be able to extract the server error
        if case .error(let code, let responseData, _, let underlyingError) = errorResponse {
            XCTAssertEqual(code, 401)
            XCTAssertEqual(responseData, data)

            if let serverErr = underlyingError as? ServerErrorResponse {
                XCTAssertEqual(serverErr.error, "Invalid authentication token")
            } else {
                XCTFail("Underlying error should be ServerErrorResponse")
            }
        } else {
            XCTFail("Should be an error response")
        }
    }
}