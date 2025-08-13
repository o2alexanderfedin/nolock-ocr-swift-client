import Foundation
import NolockOCRClient

class IntegrationTests {
    
    static func runTests() async {
        print("🧪 Running Integration Tests")
        print("============================\n")
        
        // Configure the API
        NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
        
        // Test health endpoint
        await testHealthEndpoint()
        
        // Test check OCR with sample image
        await testCheckOCR()
        
        // Test receipt OCR with sample image
        await testReceiptOCR()
        
        print("\n============================")
        print("✅ Integration tests completed")
    }
    
    static func testHealthEndpoint() async {
        print("📡 Testing health endpoint...")
        
        do {
            let response = try await HealthAPI.healthCheck()
            print("  ✅ Health check passed: \(response)")
        } catch {
            print("  ❌ Health check failed: \(error)")
        }
    }
    
    static func testCheckOCR() async {
        print("\n📄 Testing Check OCR...")
        
        // Create a minimal test image (1x1 white pixel PNG)
        let testImageData = createMinimalTestImage()
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-check-\(UUID().uuidString)")
            .appendingPathExtension("png")
        
        do {
            try testImageData.write(to: tempURL)
            defer { try? FileManager.default.removeItem(at: tempURL) }
            
            print("  📤 Sending test image to OCR service...")
            let response = try await OCROperationsAPI.processCheckOcr(body: tempURL)
            
            if let check = response.modelData {
                print("  ✅ Check OCR succeeded:")
                print("     Account: \(check.accountNumber ?? "N/A")")
                print("     Routing: \(check.routingNumber ?? "N/A")")
                print("     Amount: \(check.amount ?? 0)")
                if let date = check.date {
                    print("     Date: \(date)")
                } else {
                    print("     Date: N/A")
                }
            } else {
                print("  ⚠️  No check data in response")
            }
            
            // Also test the raw response to see date format
            print("  📊 Raw response:")
            print("     Processing time: \(response.processingTime ?? "N/A")")
            print("     Success: \(response.success ?? false)")
            if let check = response.modelData {
                print("     Check confidence: \(check.confidence ?? 0)")
                if let metadata = check.metadata {
                    print("     Metadata: \(metadata)")
                }
            }
            
        } catch let error as DecodingError {
            print("  ❌ Decoding error: \(error)")
            
            // Detailed error information for date parsing issues
            switch error {
            case .dataCorrupted(let context):
                print("     Context: \(context.codingPath)")
                print("     Description: \(context.debugDescription)")
                if let underlyingError = context.underlyingError {
                    print("     Underlying: \(underlyingError)")
                }
            default:
                break
            }
            
        } catch {
            print("  ❌ Check OCR failed: \(error)")
            
            // If it's an ErrorResponse, try to extract more info
            if let errorResponse = error as? ErrorResponse {
                switch errorResponse {
                case .error(let code, let data, let response, let decodingError):
                    print("     HTTP Code: \(code)")
                    if let data = data {
                        print("     Response size: \(data.count) bytes")
                        // Try to print raw response for debugging
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("     Raw response: \(jsonString)")
                        }
                    }
                    if let httpResponse = response as? HTTPURLResponse {
                        print("     Status: \(httpResponse.statusCode)")
                    }
                    print("     Decoding error: \(decodingError)")
                }
            }
        }
    }
    
    static func testReceiptOCR() async {
        print("\n🧾 Testing Receipt OCR...")
        
        // Create a minimal test image
        let testImageData = createMinimalTestImage()
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-receipt-\(UUID().uuidString)")
            .appendingPathExtension("png")
        
        do {
            try testImageData.write(to: tempURL)
            defer { try? FileManager.default.removeItem(at: tempURL) }
            
            print("  📤 Sending test image to OCR service...")
            let response = try await OCROperationsAPI.processReceiptOcr(body: tempURL)
            
            if let receipt = response.modelData {
                print("  ✅ Receipt OCR succeeded:")
                if let merchant = receipt.merchant {
                    print("     Merchant: \(merchant.name ?? "N/A")")
                }
                if let totals = receipt.totals {
                    print("     Total: $\(totals.total ?? 0)")
                }
            } else {
                print("  ⚠️  No receipt data in response")
            }
            
        } catch let error as DecodingError {
            print("  ❌ Decoding error: \(error)")
            
            switch error {
            case .dataCorrupted(let context):
                print("     Context: \(context.codingPath)")
                print("     Description: \(context.debugDescription)")
            default:
                break
            }
            
        } catch {
            print("  ❌ Receipt OCR failed: \(error)")
        }
    }
    
    // Create a minimal valid PNG image for testing
    static func createMinimalTestImage() -> Data {
        // Minimal 1x1 white PNG
        let pngBytes: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,  // IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,  // 1x1 dimensions
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,  // 8-bit RGB
            0xDE,                                              // CRC
            0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54,  // IDAT chunk
            0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0xFE, 0xFF,  // Compressed data
            0x00, 0xFF, 0xFF, 0x01,                          // White pixel
            0x00, 0x05, 0x00, 0x01,                          // CRC
            0x47, 0xB3, 0x51, 0xFC,                          // More CRC
            0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,  // IEND chunk
            0xAE, 0x42, 0x60, 0x82                           // CRC
        ]
        return Data(pngBytes)
    }
}