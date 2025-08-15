import Foundation
import NolockOCRClient

/// Simple usage example showing the difference between direct API and wrapper
func demonstrateWrapperUsage() async {
    print("📚 OCROperationsWrapper Usage Example")
    print("=====================================\n")
    
    // Configure API endpoint
    NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
    
    // Example image paths
    let heicImageURL = URL(fileURLWithPath: "/path/to/image.heic")
    let jpegImageURL = URL(fileURLWithPath: "/path/to/image.jpg")
    
    print("❌ WITHOUT Wrapper (manual conversion needed):")
    print("------------------------------------------------")
    print("""
    // You need to manually check and convert HEIC images
    if imageURL.pathExtension.lowercased() == "heic" {
        let jpegURL = try convertHEICToJPEG(...)  // Manual conversion
        defer { try? FileManager.default.removeItem(at: jpegURL) }
        let response = try await OCROperationsAPI.processCheckOcr(body: jpegURL)
    } else {
        let response = try await OCROperationsAPI.processCheckOcr(body: imageURL)
    }
    """)
    
    print("\n✅ WITH Wrapper (automatic conversion):")
    print("------------------------------------------------")
    print("""
    // Just pass any image URL - HEIC conversion is automatic!
    let response = try await OCROperationsWrapper.processCheckOcr(imageURL: imageURL)
    
    // That's it! The wrapper handles:
    // - HEIC detection
    // - JPEG conversion at 95% quality
    // - Temporary file cleanup
    """)
    
    print("\n🎯 Real Usage Example:")
    print("------------------------------------------------\n")
    
    // Real example with error handling
    do {
        // Process any image - HEIC, JPEG, PNG, etc.
        // The wrapper automatically converts HEIC to JPEG if needed
        let anyImageURL = URL(fileURLWithPath: TestResources.getTestImagePath())
        
        if FileManager.default.fileExists(atPath: anyImageURL.path) {
            print("Processing image: \(anyImageURL.lastPathComponent)")
            
            // One line - handles everything!
            let response = try await OCROperationsWrapper.processCheckOcr(imageURL: anyImageURL)
            
            if let check = response.modelData {
                print("✅ Success! Extracted data:")
                print("   Amount: $\(check.amount ?? 0)")
                print("   Payee: \(check.payee ?? "N/A")")
            }
        }
        
    } catch {
        print("Error: \(error)")
    }
    
    print("\n💡 Configuration Options:")
    print("------------------------------------------------")
    print("""
    // Customize JPEG quality (default: 0.95)
    OCROperationsWrapper.jpegQuality = 0.90
    
    // Control temp file cleanup (default: true)
    OCROperationsWrapper.autoCleanupTempFiles = false
    
    // Use with completion handlers (non-async)
    OCROperationsWrapper.processCheckOcr(imageURL: url) { result in
        switch result {
        case .success(let response):
            // Handle success
        case .failure(let error):
            // Handle error
        }
    }
    """)
}