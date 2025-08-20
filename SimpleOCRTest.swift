import Foundation
import NolockOCRClient

// Minimal test - just call OCR service
@main
struct SimpleOCRTest {
    static func main() async {
        print("Testing OCR Service...")
        
        do {
            // Test with sample HEIC image
            let testImagePath = "test-check.jpg"
            let imageURL = URL(fileURLWithPath: testImagePath)
            
            if FileManager.default.fileExists(atPath: testImagePath) {
                print("Processing image: \(testImagePath)")
                let response = try await OCROperationsWrapper.processCheckOcr(imageURL: imageURL)
                
                if let check = response.modelData {
                    print("✅ Success!")
                    print("Amount: \(check.amount ?? 0)")
                    print("Payee: \(check.payee ?? "N/A")")
                    print("Date: \(check.date?.description ?? "N/A")")
                } else {
                    print("❌ No data in response")
                }
            } else {
                print("⚠️ Place test-check.jpg in current directory")
                
                // Try with Data overload using minimal test data
                print("\nTrying with minimal data...")
                let testData = Data([0xFF, 0xD8, 0xFF]) // Minimal JPEG header
                let response = try await OCROperationsWrapper.processCheckOcr(imageData: testData)
                print("Response: \(response)")
            }
        } catch {
            print("❌ Error: \(error)")
        }
    }
}