import Foundation
import NolockOCRClient

/// Test the OCROperationsWrapper with automatic HEIC conversion
class WrapperTest {
    
    static func runTests() async {
        print("🎁 Testing OCROperationsWrapper")
        print("================================\n")
        
        // Configure the API
        NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
        
        // Configure wrapper settings
        OCROperationsWrapper.jpegQuality = 0.95
        OCROperationsWrapper.autoCleanupTempFiles = true
        
        // Test with HEIC image
        await testWithHEICImage()
        
        // Test with regular JPEG
        await testWithJPEGImage()
        
        print("\n================================")
        print("✅ Wrapper tests completed")
    }
    
    static func testWithHEICImage() async {
        print("📱 Testing with HEIC image...")
        
        let heicImagePath = "/Users/alexanderfedin/Projects/nolock.social/Nolock.social.apps/nolock-ocr-swift-client/ExampleApp/IMG_4171.heic"
        let heicURL = URL(fileURLWithPath: heicImagePath)
        
        guard FileManager.default.fileExists(atPath: heicImagePath) else {
            print("  ⚠️ HEIC test image not found")
            return
        }
        
        do {
            print("  🔄 Wrapper will automatically convert HEIC to JPEG...")
            
            // Test Check OCR - wrapper handles conversion automatically
            let checkResponse = try await OCROperationsWrapper.processCheckOcr(imageURL: heicURL)
            
            if let check = checkResponse.modelData {
                print("  ✅ Check OCR succeeded (HEIC → JPEG conversion automatic):")
                print("     Amount: $\(check.amount ?? 0)")
                print("     Payee: \(check.payee ?? "N/A")")
                print("     Date: \(check.date?.description ?? "N/A")")
                print("     Confidence: \(check.confidence ?? 0)")
            }
            
        } catch {
            print("  ❌ Error: \(error)")
        }
    }
    
    static func testWithJPEGImage() async {
        print("\n📷 Testing with JPEG image...")
        
        // Create a test JPEG from the HEIC first
        let heicImagePath = "/Users/alexanderfedin/Projects/nolock.social/Nolock.social.apps/nolock-ocr-swift-client/ExampleApp/IMG_4171.heic"
        
        guard FileManager.default.fileExists(atPath: heicImagePath) else {
            print("  ⚠️ Source image not found")
            return
        }
        
        do {
            // Convert HEIC to JPEG for testing
            let heicURL = URL(fileURLWithPath: heicImagePath)
            let jpegURL = try OCROperationsWrapper.convertHEICToJPEG(heicURL: heicURL, quality: 0.95)
            defer { try? FileManager.default.removeItem(at: jpegURL) }
            
            print("  📤 Processing JPEG directly (no conversion needed)...")
            
            // Test Receipt OCR with JPEG - no conversion needed
            let receiptResponse = try await OCROperationsWrapper.processReceiptOcr(imageURL: jpegURL)
            
            if let receipt = receiptResponse.modelData {
                print("  ✅ Receipt OCR succeeded (direct JPEG processing):")
                if let merchant = receipt.merchant {
                    print("     Merchant: \(merchant.name ?? "N/A")")
                }
                if let totals = receipt.totals {
                    print("     Total: $\(totals.total ?? 0)")
                }
                print("     Confidence: \(receipt.confidence ?? 0)")
            }
            
        } catch {
            print("  ❌ Error: \(error)")
        }
    }
    
    static func testWithCompletionHandler() {
        print("\n🔄 Testing with completion handler (non-async)...")
        
        let heicImagePath = "/Users/alexanderfedin/Projects/nolock.social/Nolock.social.apps/nolock-ocr-swift-client/ExampleApp/IMG_4171.heic"
        let heicURL = URL(fileURLWithPath: heicImagePath)
        
        guard FileManager.default.fileExists(atPath: heicImagePath) else {
            print("  ⚠️ HEIC test image not found")
            return
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        OCROperationsWrapper.processCheckOcr(imageURL: heicURL) { result in
            switch result {
            case .success(let response):
                if let check = response.modelData {
                    print("  ✅ Check OCR with completion handler succeeded:")
                    print("     Amount: $\(check.amount ?? 0)")
                    print("     Payee: \(check.payee ?? "N/A")")
                }
            case .failure(let error):
                print("  ❌ Error: \(error)")
            }
            semaphore.signal()
        }
        
        // Wait for completion
        _ = semaphore.wait(timeout: .now() + 30)
    }
}

// Run wrapper tests
public func runWrapperTests() async {
    await WrapperTest.runTests()
    
    // Also test completion handler version
    WrapperTest.testWithCompletionHandler()
}