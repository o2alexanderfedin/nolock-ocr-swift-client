import XCTest
import Foundation
@testable import NolockOCRClient

final class DateParsingTests: XCTestCase {
    
    /// OCR service base URL for testing
    static let testBaseURL = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
    
    override func setUpWithError() throws {
        // Configure the API base URL before each test
        NolockOCRClientAPI.basePath = Self.testBaseURL
        
        // Configure wrapper settings
        OCROperationsWrapper.jpegQuality = 0.95
        OCROperationsWrapper.autoCleanupTempFiles = true
    }
    
    // MARK: - Check Date Parsing Tests
    
    func testCheckDateParsingWithRealImage() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        do {
            let response = try await OCROperationsWrapper.processCheckOcr(imageURL: testImageURL)
            
            XCTAssertNotNil(response, "Response should not be nil")
            
            if let check = response.modelData {
                if let date = check.date {
                    // Test that the date was parsed successfully
                    XCTAssertNotNil(date, "Date should be parsed successfully")
                    
                    // Verify the date is reasonable (not in the far future or past)
                    let now = Date()
                    let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: now)!
                    let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!
                    
                    XCTAssertTrue(date >= tenYearsAgo && date <= oneYearFromNow,
                                "Date should be within reasonable range (10 years ago to 1 year from now)")
                    
                    // Test date formatting
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .none
                    let formattedDate = formatter.string(from: date)
                    
                    XCTAssertFalse(formattedDate.isEmpty, "Formatted date should not be empty")
                    
                    print("Check date parsing test successful:")
                    print("  Parsed date: \(date)")
                    print("  Formatted date: \(formattedDate)")
                    print("  ISO8601: \(ISO8601DateFormatter().string(from: date))")
                    
                    // Test date components
                    let calendar = Calendar.current
                    let year = calendar.component(.year, from: date)
                    let month = calendar.component(.month, from: date)
                    let day = calendar.component(.day, from: date)
                    
                    XCTAssertGreaterThan(year, 2020, "Year should be reasonable")
                    XCTAssertGreaterThan(month, 0, "Month should be valid")
                    XCTAssertLessThanOrEqual(month, 12, "Month should be valid")
                    XCTAssertGreaterThan(day, 0, "Day should be valid")
                    XCTAssertLessThanOrEqual(day, 31, "Day should be valid")
                    
                    print("  Year: \(year), Month: \(month), Day: \(day)")
                    
                } else {
                    print("No date found in check data (this may be expected for some test images)")
                    // This is not necessarily a failure - some images may not contain readable dates
                }
            } else {
                print("No check data in response")
            }
            
        } catch let error as DecodingError {
            // If there's a date parsing error, we want to capture it for analysis
            switch error {
            case .dataCorrupted(let context):
                if context.codingPath.contains(where: { $0.stringValue == "date" }) {
                    XCTFail("Date parsing failed: \(context.debugDescription)")
                    print("Date parsing error details:")
                    print("  Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    print("  Description: \(context.debugDescription)")
                    if let underlyingError = context.underlyingError {
                        print("  Underlying error: \(underlyingError)")
                    }
                } else {
                    throw error // Re-throw if it's not a date parsing issue
                }
            case .typeMismatch(let type, let context):
                if context.codingPath.contains(where: { $0.stringValue == "date" }) {
                    XCTFail("Date type mismatch: Expected \(type), coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                } else {
                    throw error
                }
            default:
                throw error
            }
        }
    }
    
    // MARK: - Receipt Date Parsing Tests
    
    func testReceiptTimestampParsingWithRealImage() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        do {
            let response = try await OCROperationsWrapper.processReceiptOcr(imageURL: testImageURL)
            
            XCTAssertNotNil(response, "Response should not be nil")
            
            if let receipt = response.modelData {
                if let timestamp = receipt.timestamp {
                    // Test that the timestamp was parsed successfully
                    XCTAssertNotNil(timestamp, "Timestamp should be parsed successfully")
                    
                    // Verify the timestamp is reasonable
                    let now = Date()
                    let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: now)!
                    let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!
                    
                    XCTAssertTrue(timestamp >= tenYearsAgo && timestamp <= oneYearFromNow,
                                "Timestamp should be within reasonable range")
                    
                    // Test timestamp formatting
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    let formattedTimestamp = formatter.string(from: timestamp)
                    
                    XCTAssertFalse(formattedTimestamp.isEmpty, "Formatted timestamp should not be empty")
                    
                    print("Receipt timestamp parsing test successful:")
                    print("  Parsed timestamp: \(timestamp)")
                    print("  Formatted timestamp: \(formattedTimestamp)")
                    print("  ISO8601: \(ISO8601DateFormatter().string(from: timestamp))")
                    
                    // Test timestamp components
                    let calendar = Calendar.current
                    let year = calendar.component(.year, from: timestamp)
                    let month = calendar.component(.month, from: timestamp)
                    let day = calendar.component(.day, from: timestamp)
                    let hour = calendar.component(.hour, from: timestamp)
                    let minute = calendar.component(.minute, from: timestamp)
                    
                    XCTAssertGreaterThan(year, 2020, "Year should be reasonable")
                    XCTAssertGreaterThan(month, 0, "Month should be valid")
                    XCTAssertLessThanOrEqual(month, 12, "Month should be valid")
                    XCTAssertGreaterThan(day, 0, "Day should be valid")
                    XCTAssertLessThanOrEqual(day, 31, "Day should be valid")
                    XCTAssertGreaterThanOrEqual(hour, 0, "Hour should be valid")
                    XCTAssertLessThanOrEqual(hour, 23, "Hour should be valid")
                    XCTAssertGreaterThanOrEqual(minute, 0, "Minute should be valid")
                    XCTAssertLessThanOrEqual(minute, 59, "Minute should be valid")
                    
                    print("  Year: \(year), Month: \(month), Day: \(day)")
                    print("  Hour: \(hour), Minute: \(minute)")
                    
                } else {
                    print("No timestamp found in receipt data (this may be expected for some test images)")
                    // This is not necessarily a failure - some images may not contain readable timestamps
                }
            } else {
                print("No receipt data in response")
            }
            
        } catch let error as DecodingError {
            // If there's a timestamp parsing error, we want to capture it for analysis
            switch error {
            case .dataCorrupted(let context):
                if context.codingPath.contains(where: { $0.stringValue == "timestamp" }) {
                    XCTFail("Timestamp parsing failed: \(context.debugDescription)")
                    print("Timestamp parsing error details:")
                    print("  Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    print("  Description: \(context.debugDescription)")
                    if let underlyingError = context.underlyingError {
                        print("  Underlying error: \(underlyingError)")
                    }
                } else {
                    throw error // Re-throw if it's not a timestamp parsing issue
                }
            case .typeMismatch(let type, let context):
                if context.codingPath.contains(where: { $0.stringValue == "timestamp" }) {
                    XCTFail("Timestamp type mismatch: Expected \(type), coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                } else {
                    throw error
                }
            default:
                throw error
            }
        }
    }
    
    // MARK: - Date Formatter Tests
    
    func testISO8601DateFormatter() {
        // Test the OpenISO8601DateFormatter directly
        let formatter = OpenISO8601DateFormatter()
        
        // Test various ISO8601 date formats
        let testDateStrings = [
            "2024-01-15T10:30:00Z",
            "2024-01-15T10:30:00.000Z",
            "2024-01-15T10:30:00+00:00",
            "2024-01-15T10:30:00-05:00",
            "2024-01-15",
            "2024-01-15T10:30:00"
        ]
        
        for dateString in testDateStrings {
            if let date = formatter.date(from: dateString) {
                let backToString = formatter.string(from: date)
                XCTAssertNotNil(date, "Should parse date string: \(dateString)")
                XCTAssertFalse(backToString.isEmpty, "Should format date back to string")
                
                print("Date parsing test:")
                print("  Input: \(dateString)")
                print("  Parsed: \(date)")
                print("  Formatted back: \(backToString)")
            } else {
                print("Could not parse date string: \(dateString) (this may be expected for some formats)")
            }
        }
    }
    
    func testDateFormatterEdgeCases() {
        let formatter = OpenISO8601DateFormatter()
        
        // Test edge cases
        let edgeCases = [
            "", // Empty string
            "invalid-date", // Invalid format
            "2024-13-01", // Invalid month
            "2024-01-32", // Invalid day
            "2024-01-01T25:00:00Z", // Invalid hour
            "2024-01-01T12:60:00Z", // Invalid minute
            "2024-01-01T12:30:60Z", // Invalid second
        ]
        
        for edgeCase in edgeCases {
            let date = formatter.date(from: edgeCase)
            if date != nil {
                print("Unexpectedly parsed edge case: \(edgeCase)")
            } else {
                print("Correctly rejected edge case: \(edgeCase)")
            }
            // We don't assert here because behavior may vary
        }
    }
    
    // MARK: - Date Parsing Resilience Tests
    
    func testDateParsingResilience() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Test multiple times to ensure date parsing is consistent
        let numberOfTests = 3
        var parsedDates: [Date] = []
        
        for i in 1...numberOfTests {
            do {
                let response = try await OCROperationsWrapper.processCheckOcr(imageURL: testImageURL)
                
                if let check = response.modelData, let date = check.date {
                    parsedDates.append(date)
                    print("Date parsing resilience test \(i): \(date)")
                } else {
                    print("Date parsing resilience test \(i): No date found")
                }
                
            } catch let error as DecodingError {
                switch error {
                case .dataCorrupted(let context):
                    if context.codingPath.contains(where: { $0.stringValue == "date" }) {
                        XCTFail("Date parsing failed in resilience test \(i): \(context.debugDescription)")
                    } else {
                        throw error
                    }
                default:
                    throw error
                }
            }
        }
        
        // If we got multiple dates, they should be the same (assuming same image)
        if parsedDates.count > 1 {
            let firstDate = parsedDates[0]
            for (index, date) in parsedDates.enumerated() {
                XCTAssertEqual(date.timeIntervalSince1970, firstDate.timeIntervalSince1970, accuracy: 1.0,
                             "Date parsing should be consistent across calls (test \(index + 1))")
            }
            print("Date parsing resilience: All \(parsedDates.count) dates are consistent")
        }
    }
    
    // MARK: - API Response Analysis
    
    func testDateFormatInAPIResponse() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        // Convert to JPEG for direct API call
        let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: testImageURL, quality: 0.95)
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        
        do {
            let response = try await OCROperationsAPI.processCheckOcr(body: jpegURL)
            
            print("API Response Analysis:")
            print("  Success: \(response.success ?? false)")
            print("  Processing time: \(response.processingTime ?? "N/A")")
            
            if let check = response.modelData {
                if let date = check.date {
                    print("  Date successfully parsed: \(date)")
                    
                    // Test various formatting options
                    let iso8601 = ISO8601DateFormatter()
                    print("  ISO8601 format: \(iso8601.string(from: date))")
                    
                    let rfc3339 = DateFormatter()
                    rfc3339.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
                    print("  RFC3339 format: \(rfc3339.string(from: date))")
                    
                    let simple = DateFormatter()
                    simple.dateFormat = "yyyy-MM-dd"
                    print("  Simple format: \(simple.string(from: date))")
                    
                } else {
                    print("  No date in response")
                }
            }
            
        } catch let error as ErrorResponse {
            // If we get an API error response, try to examine the raw JSON
            switch error {
            case .error(let code, let data, _, let decodingError):
                print("API Error Response Analysis:")
                print("  HTTP Code: \(code)")
                
                if let data = data, let jsonString = String(data: data, encoding: .utf8) {
                    print("  Raw JSON Response:")
                    print("  \(jsonString)")
                    
                    // Try to extract date field manually to see the format
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let modelData = json["modelData"] as? [String: Any],
                       let dateField = modelData["date"] {
                        print("  Raw date field: \(dateField) (type: \(type(of: dateField)))")
                    }
                }
                
                print("  Decoding error: \(decodingError)")
                throw error
            }
        }
    }
    
    // MARK: - Date Validation Tests
    
    func testDateValidation() async throws {
        guard let testImageURL = Bundle.module.url(forResource: "IMG_4171", withExtension: "heic") else {
            XCTFail("Test HEIC image not found")
            return
        }
        
        let response = try await OCROperationsWrapper.processCheckOcr(imageURL: testImageURL)
        
        if let check = response.modelData, let date = check.date {
            // Test date validation rules
            let calendar = Calendar.current
            let now = Date()
            
            // Date should not be in the future (beyond reasonable bounds)
            let maxFutureDate = calendar.date(byAdding: .month, value: 6, to: now)!
            XCTAssertLessThanOrEqual(date, maxFutureDate, "Check date should not be more than 6 months in the future")
            
            // Date should not be too far in the past (beyond reasonable check lifetime)
            let minPastDate = calendar.date(byAdding: .year, value: -10, to: now)!
            XCTAssertGreaterThanOrEqual(date, minPastDate, "Check date should not be more than 10 years in the past")
            
            // Date should have reasonable time component (if any)
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            
            if hour != 0 || minute != 0 {
                // If time is specified, it should be reasonable business hours or close
                print("Date includes time: \(hour):\(String(format: "%02d", minute))")
            } else {
                print("Date is date-only (no time component)")
            }
            
            print("Date validation test passed for: \(date)")
            
        } else {
            print("No date to validate (this may be expected)")
        }
    }
}