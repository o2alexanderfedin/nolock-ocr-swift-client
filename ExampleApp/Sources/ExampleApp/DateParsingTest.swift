import Foundation
import NolockOCRClient

// Test specifically for the date parsing issue
func testDateParsingIssue() async {
    print("\n🔍 Testing Date Parsing Issue")
    print("================================\n")
    
    // Configure the API
    NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
    
    // Use the actual test image if it exists
    let testImagePath = "test-check.jpg"
    let testImageURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(testImagePath)
    
    if FileManager.default.fileExists(atPath: testImageURL.path) {
        print("📎 Using test image: \(testImagePath)")
        
        do {
            print("📤 Sending check image to OCR service...")
            let response = try await OCROperationsAPI.processCheckOcr(body: testImageURL)
            
            print("✅ Request succeeded!")
            print("   Success: \(response.success ?? false)")
            print("   Processing time: \(response.processingTime ?? "N/A")")
            
            if let check = response.modelData {
                print("\n📋 Check Data:")
                print("   Check number: \(check.checkNumber ?? "N/A")")
                print("   Account: \(check.accountNumber ?? "N/A")")
                print("   Routing: \(check.routingNumber ?? "N/A")")
                print("   Amount: $\(check.amount ?? 0)")
                print("   Payee: \(check.payee ?? "N/A")")
                print("   Payer: \(check.payer ?? "N/A")")
                
                // This is where the date parsing issue occurs
                if let date = check.date {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    print("   Date: \(formatter.string(from: date))")
                } else {
                    print("   Date: N/A")
                }
                
                print("   Confidence: \(check.confidence ?? 0)")
                print("   Valid input: \(check.isValidInput ?? false)")
            } else {
                print("⚠️  No check data in response")
            }
            
        } catch let error as DecodingError {
            print("❌ DECODING ERROR DETECTED!")
            print("   This is the date parsing issue.\n")
            
            switch error {
            case .dataCorrupted(let context):
                print("📍 Error Details:")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                print("   Description: \(context.debugDescription)")
                if let underlyingError = context.underlyingError {
                    print("   Underlying: \(underlyingError)")
                }
                
                // Check if it's specifically the date field
                if context.codingPath.contains(where: { $0.stringValue == "date" }) {
                    print("\n🎯 CONFIRMED: The error is in the 'date' field parsing")
                    print("   The API is returning a date format that doesn't match")
                    print("   the expected ISO8601 format used by the decoder.\n")
                    print("   Possible solutions:")
                    print("   1. Update OpenISO8601DateFormatter to handle the actual format")
                    print("   2. Make the date field a String instead of Date")
                    print("   3. Use a custom date decoding strategy")
                }
                
            case .typeMismatch(let type, let context):
                print("📍 Type Mismatch:")
                print("   Expected type: \(type)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                print("   Description: \(context.debugDescription)")
                
            default:
                print("📍 Other decoding error: \(error)")
            }
            
        } catch let error as ErrorResponse {
            print("❌ API Error Response:")
            switch error {
            case .error(let code, let data, _, let decodingError):
                print("   HTTP Code: \(code)")
                
                if let data = data {
                    print("   Response size: \(data.count) bytes")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("\n📦 Raw JSON Response:")
                        print("   \(jsonString)")
                        
                        // Try to parse and pretty print
                        if let json = try? JSONSerialization.jsonObject(with: data, options: []),
                           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                           let prettyString = String(data: prettyData, encoding: .utf8) {
                            print("\n📋 Formatted JSON:")
                            print(prettyString)
                        }
                    }
                }
                
                print("\n🔍 Decoding error details:")
                print("   \(decodingError)")
            }
            
        } catch {
            print("❌ Unexpected error: \(error)")
        }
        
    } else {
        print("⚠️  Test image not found: \(testImagePath)")
        print("   Please ensure test-check.jpg exists in the current directory")
    }
}

// Test receipt date parsing
func testReceiptDateParsing() async {
    print("\n🧾 Testing Receipt Date Parsing")
    print("================================\n")
    
    // Use the same test image
    let testImagePath = "test-check.jpg"
    let testImageURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(testImagePath)
    
    if FileManager.default.fileExists(atPath: testImageURL.path) {
        do {
            print("📤 Sending image to Receipt OCR service...")
            let response = try await OCROperationsAPI.processReceiptOcr(body: testImageURL)
            
            print("✅ Receipt request succeeded!")
            print("   Processing time: \(response.processingTime ?? "N/A")")
            
            if let receipt = response.modelData {
                print("\n📋 Receipt Data:")
                
                // This is where date parsing would occur for receipts
                if let timestamp = receipt.timestamp {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    print("   Timestamp: \(formatter.string(from: timestamp))")
                } else {
                    print("   Timestamp: N/A")
                }
                
                if let merchant = receipt.merchant {
                    print("   Merchant: \(merchant.name ?? "N/A")")
                }
                
                if let totals = receipt.totals {
                    print("   Total: $\(totals.total ?? 0)")
                }
                
                print("   Confidence: \(receipt.confidence ?? 0)")
                print("   Valid input: \(receipt.isValidInput ?? false)")
            }
            
        } catch let error as DecodingError {
            print("❌ DECODING ERROR in Receipt!")
            switch error {
            case .dataCorrupted(let context):
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                print("   Description: \(context.debugDescription)")
                
                if context.codingPath.contains(where: { $0.stringValue == "timestamp" }) {
                    print("\n🎯 Date parsing error in Receipt timestamp field!")
                }
            default:
                print("   Error: \(error)")
            }
        } catch {
            print("❌ Receipt OCR error: \(error)")
        }
    }
}

// Run this test directly
public func runDateParsingTest() async {
    await testDateParsingIssue()
    await testReceiptDateParsing()
}