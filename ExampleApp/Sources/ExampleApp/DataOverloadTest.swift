import Foundation
import NolockOCRClient

/// Test the new Data overloads for OCROperationsWrapper
class DataOverloadTest {
    
    static func runTests() async {
        print("🔍 Testing Data Overloads for OCROperationsWrapper")
        print("=================================================\n")
        
        // Configure the API
        NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
        
        // Test with Data from embedded resource
        await testCheckOcrWithData()
        await testReceiptOcrWithData()
        
        print("\n=================================================")
        print("✅ Data overload tests completed")
    }
    
    static func testCheckOcrWithData() async {
        print("📱 Test 1: Check OCR with Data input")
        
        // Get test image URL
        guard let imageURL = TestResources.getTestImageURL() else {
            print("  ⚠️ Test image not found")
            return
        }
        
        do {
            // Load image as Data
            let imageData = try Data(contentsOf: imageURL)
            print("  📊 Loaded image data: \(imageData.count) bytes")
            
            // Process using Data overload
            print("  🔄 Processing with OCROperationsWrapper.processCheckOcr(imageData:)...")
            let response = try await OCROperationsWrapper.processCheckOcr(imageData: imageData)
            
            if response.success == true {
                print("  ✅ Successfully processed using Data overload!")
                if let check = response.modelData {
                    print("     Amount: $\(check.amount ?? 0)")
                    print("     Payee: \(check.payee ?? "N/A")")
                }
            } else {
                print("  ⚠️ Processing returned success=false")
            }
            
        } catch {
            print("  ❌ Error: \(error)")
        }
    }
    
    static func testReceiptOcrWithData() async {
        print("\n🧾 Test 2: Receipt OCR with Data input")
        
        // Get test image URL
        guard let imageURL = TestResources.getTestImageURL() else {
            print("  ⚠️ Test image not found")
            return
        }
        
        do {
            // Load image as Data
            let imageData = try Data(contentsOf: imageURL)
            print("  📊 Loaded image data: \(imageData.count) bytes")
            
            // Process using Data overload
            print("  🔄 Processing with OCROperationsWrapper.processReceiptOcr(imageData:)...")
            let response = try await OCROperationsWrapper.processReceiptOcr(imageData: imageData)
            
            if response.success == true {
                print("  ✅ Successfully processed using Data overload!")
                if let receipt = response.modelData {
                    if let totals = receipt.totals {
                        print("     Total: $\(totals.total ?? 0)")
                    }
                    if let merchant = receipt.merchant {
                        print("     Merchant: \(merchant.name ?? "N/A")")
                    }
                }
            } else {
                print("  ⚠️ Processing returned success=false")
            }
            
        } catch {
            print("  ❌ Error: \(error)")
        }
    }
    
    static func testCompletionHandlerWithData() {
        print("\n📞 Test 3: Completion handler with Data input")
        
        // Get test image URL
        guard let imageURL = TestResources.getTestImageURL() else {
            print("  ⚠️ Test image not found")
            return
        }
        
        do {
            // Load image as Data
            let imageData = try Data(contentsOf: imageURL)
            print("  📊 Loaded image data: \(imageData.count) bytes")
            
            let expectation = DispatchSemaphore(value: 0)
            
            // Process using completion handler
            print("  🔄 Processing with completion handler...")
            OCROperationsWrapper.processCheckOcr(imageData: imageData) { result in
                switch result {
                case .success(let response):
                    print("  ✅ Successfully processed using completion handler!")
                    if let check = response.modelData {
                        print("     Amount: $\(check.amount ?? 0)")
                    }
                case .failure(let error):
                    print("  ❌ Error: \(error)")
                }
                expectation.signal()
            }
            
            // Wait for completion
            _ = expectation.wait(timeout: .now() + 30)
            
        } catch {
            print("  ❌ Error loading data: \(error)")
        }
    }
}

// Public function to run data overload tests
public func runDataOverloadTests() async {
    await DataOverloadTest.runTests()
}