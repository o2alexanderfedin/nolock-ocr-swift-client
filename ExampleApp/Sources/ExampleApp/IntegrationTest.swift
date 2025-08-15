import Foundation
import NolockOCRClient
#if canImport(CoreImage)
import CoreImage
#endif
#if canImport(ImageIO)
import ImageIO
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

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
        
        // Use the HEIC image and convert to JPEG
        let heicImagePath = "/Users/alexanderfedin/Projects/nolock.social/Nolock.social.apps/nolock-ocr-swift-client/ExampleApp/IMG_4171.heic"
        
        guard FileManager.default.fileExists(atPath: heicImagePath) else {
            print("  ⚠️ HEIC image not found at: \(heicImagePath)")
            print("     Using minimal test image instead...")
            
            // Fallback to minimal test image
            let testImageData = createMinimalTestImage()
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("test-check-\(UUID().uuidString)")
                .appendingPathExtension("png")
            
            do {
                try testImageData.write(to: tempURL)
                defer { try? FileManager.default.removeItem(at: tempURL) }
                try await performCheckOCR(with: tempURL)
            } catch {
                print("  ❌ Error: \(error)")
            }
            return
        }
        
        // Convert HEIC to JPEG
        print("  🔄 Converting HEIC to JPEG (95% quality)...")
        
        do {
            let jpegURL = try convertHEICToJPEG(heicPath: heicImagePath, quality: 0.95)
            defer { try? FileManager.default.removeItem(at: jpegURL) }
            
            print("  ✅ Conversion successful, JPEG saved to: \(jpegURL.lastPathComponent)")
            try await performCheckOCR(with: jpegURL)
        } catch {
            print("  ❌ Error converting or processing: \(error)")
        }
    }
    
    private static func performCheckOCR(with url: URL) async throws {
        print("  📤 Sending test image to OCR service...")
        let response = try await OCROperationsAPI.processCheckOcr(body: url)
        
        if let check = response.modelData {
            print("  ✅ Check OCR succeeded:")
            print("     Check number: \(check.checkNumber ?? "N/A")")
            print("     Account: \(check.accountNumber ?? "N/A")")
            print("     Routing: \(check.routingNumber ?? "N/A")")
            print("     Amount: $\(check.amount ?? 0)")
            print("     Payee: \(check.payee ?? "N/A")")
            print("     Payer: \(check.payer ?? "N/A")")
            if let date = check.date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                print("     Date: \(formatter.string(from: date))")
            } else {
                print("     Date: N/A")
            }
            print("     Bank: \(check.bankName ?? "N/A")")
            print("     Memo: \(check.memo ?? "N/A")")
        } else {
            print("  ⚠️  No check data in response")
        }
        
        // Also test the raw response
        print("  📊 Raw response:")
        print("     Processing time: \(response.processingTime ?? "N/A")")
        print("     Success: \(response.success ?? false)")
        if let check = response.modelData {
            print("     Check confidence: \(check.confidence ?? 0)")
            print("     Valid input: \(check.isValidInput ?? false)")
            if let metadata = check.metadata {
                print("     Metadata: \(metadata)")
            }
        }
    }
    
    static func testReceiptOCR() async {
        print("\n🧾 Testing Receipt OCR...")
        
        // Use the same HEIC image as for checks
        let heicImagePath = "/Users/alexanderfedin/Projects/nolock.social/Nolock.social.apps/nolock-ocr-swift-client/ExampleApp/IMG_4171.heic"
        
        guard FileManager.default.fileExists(atPath: heicImagePath) else {
            print("  ⚠️ HEIC image not found at: \(heicImagePath)")
            print("     Using minimal test image instead...")
            
            // Fallback to minimal test image
            let testImageData = createMinimalTestImage()
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("test-receipt-\(UUID().uuidString)")
                .appendingPathExtension("png")
            
            do {
                try testImageData.write(to: tempURL)
                defer { try? FileManager.default.removeItem(at: tempURL) }
                try await performReceiptOCR(with: tempURL)
            } catch {
                print("  ❌ Error: \(error)")
            }
            return
        }
        
        // Convert HEIC to JPEG
        print("  🔄 Converting HEIC to JPEG (95% quality)...")
        
        do {
            let jpegURL = try convertHEICToJPEG(heicPath: heicImagePath, quality: 0.95)
            defer { try? FileManager.default.removeItem(at: jpegURL) }
            
            print("  ✅ Conversion successful, JPEG saved to: \(jpegURL.lastPathComponent)")
            try await performReceiptOCR(with: jpegURL)
        } catch {
            print("  ❌ Error converting or processing: \(error)")
        }
    }
    
    private static func performReceiptOCR(with url: URL) async throws {
        print("  📤 Sending test image to OCR service...")
        let response = try await OCROperationsAPI.processReceiptOcr(body: url)
        
        if let receipt = response.modelData {
            print("  ✅ Receipt OCR succeeded:")
            if let merchant = receipt.merchant {
                print("     Merchant: \(merchant.name ?? "N/A")")
                print("     Address: \(merchant.address ?? "N/A")")
                print("     Phone: \(merchant.phone ?? "N/A")")
            }
            if let totals = receipt.totals {
                print("     Subtotal: $\(totals.subtotal ?? 0)")
                print("     Tax: $\(totals.tax ?? 0)")
                print("     Total: $\(totals.total ?? 0)")
                print("     Tip: $\(totals.tip ?? 0)")
            }
            if let timestamp = receipt.timestamp {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                print("     Timestamp: \(formatter.string(from: timestamp))")
            }
            print("     Receipt #: \(receipt.receiptNumber ?? "N/A")")
            print("     Payment: \(receipt.paymentMethod ?? "N/A")")
            
            // Show line items
            if let items = receipt.items, !items.isEmpty {
                print("     Items:")
                for item in items {
                    print("       - \(item.description ?? "Unknown") x\(item.quantity ?? 1) = $\(item.totalPrice ?? 0)")
                }
            }
        } else {
            print("  ⚠️  No receipt data in response")
        }
    }
    
    // Convert HEIC to JPEG with specified quality
    static func convertHEICToJPEG(heicPath: String, quality: Double) throws -> URL {
        let heicURL = URL(fileURLWithPath: heicPath)
        
        // Read HEIC data
        let heicData = try Data(contentsOf: heicURL)
        
        // Create CGImageSource from HEIC data
        guard let imageSource = CGImageSourceCreateWithData(heicData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw NSError(domain: "ImageConversion", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from HEIC data"])
        }
        
        // Create temporary JPEG file URL
        let jpegURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("converted-\(UUID().uuidString)")
            .appendingPathExtension("jpg")
        
        // Use strategy pattern for JPEG creation
        do {
            try ImageConversionStrategyFactory.shared.createJPEGDestination(
                at: jpegURL,
                image: cgImage,
                quality: quality
            )
        } catch {
            throw NSError(domain: "ImageConversion", code: 2, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
        }
        
        return jpegURL
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