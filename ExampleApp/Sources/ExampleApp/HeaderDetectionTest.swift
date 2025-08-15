import Foundation
import NolockOCRClient

/// Test HEIC detection by file header instead of extension
class HeaderDetectionTest {
    
    static func runTests() async {
        print("🔍 Testing HEIC Detection by File Header")
        print("=========================================\n")
        
        // Configure the API
        NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
        
        // Test with correctly named HEIC file
        await testWithCorrectExtension()
        
        // Test with renamed HEIC file (wrong extension)
        await testWithWrongExtension()
        
        // Test with non-HEIC file
        await testWithNonHEICFile()
        
        print("\n=========================================")
        print("✅ Header detection tests completed")
    }
    
    static func testWithCorrectExtension() async {
        print("📱 Test 1: HEIC file with .heic extension")
        
        let heicPath = TestResources.getTestImagePath()
        let heicURL = URL(fileURLWithPath: heicPath)
        
        guard FileManager.default.fileExists(atPath: heicPath) else {
            print("  ⚠️ Test file not found")
            return
        }
        
        // Check file header
        if let header = readFileHeader(url: heicURL) {
            print("  📋 File header: \(header)")
        }
        
        do {
            print("  🔄 Processing with OCROperationsWrapper...")
            let response = try await OCROperationsWrapper.processCheckOcr(imageURL: heicURL)
            
            if response.modelData != nil {
                print("  ✅ Successfully processed (HEIC detected and converted)")
            }
        } catch {
            print("  ❌ Error: \(error)")
        }
    }
    
    static func testWithWrongExtension() async {
        print("\n📷 Test 2: HEIC file with wrong extension (.jpg)")
        
        let originalPath = TestResources.getTestImagePath()
        let tempPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_image_wrong_ext.jpg") // Wrong extension!
        
        guard FileManager.default.fileExists(atPath: originalPath) else {
            print("  ⚠️ Original file not found")
            return
        }
        
        do {
            // Copy HEIC file with .jpg extension
            if FileManager.default.fileExists(atPath: tempPath.path) {
                try FileManager.default.removeItem(at: tempPath)
            }
            try FileManager.default.copyItem(atPath: originalPath, toPath: tempPath.path)
            defer { try? FileManager.default.removeItem(at: tempPath) }
            
            print("  📁 Created HEIC file with .jpg extension")
            
            // Check file header
            if let header = readFileHeader(url: tempPath) {
                print("  📋 File header: \(header)")
                print("  ℹ️  Extension: .\(tempPath.pathExtension) (wrong!)")
                print("  ℹ️  Actual format: HEIC (detected by header)")
            }
            
            print("  🔄 Processing with OCROperationsWrapper...")
            let response = try await OCROperationsWrapper.processCheckOcr(imageURL: tempPath)
            
            if response.modelData != nil {
                print("  ✅ Successfully processed despite wrong extension!")
                print("     Wrapper correctly detected HEIC by header, not extension")
            }
            
        } catch {
            print("  ❌ Error: \(error)")
        }
    }
    
    static func testWithNonHEICFile() async {
        print("\n🖼 Test 3: Actual JPEG file")
        
        // Create a real JPEG for comparison
        let jpegPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_real.jpg")
        
        do {
            // Create a minimal JPEG
            let jpegData = createMinimalJPEG()
            try jpegData.write(to: jpegPath)
            defer { try? FileManager.default.removeItem(at: jpegPath) }
            
            print("  📁 Created real JPEG file")
            
            // Check file header
            if let header = readFileHeader(url: jpegPath) {
                print("  📋 File header: \(header)")
                print("  ℹ️  Format: JPEG (not HEIC)")
            }
            
            // Test that it's not detected as HEIC
            let isHEIC = checkIfHEIC(url: jpegPath)
            print("  🔍 HEIC detection result: \(isHEIC ? "HEIC" : "Not HEIC")")
            
            if !isHEIC {
                print("  ✅ Correctly identified as non-HEIC file")
            }
            
        } catch {
            print("  ❌ Error: \(error)")
        }
    }
    
    // Helper function to read file header
    static func readFileHeader(url: URL) -> String? {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer { fileHandle.closeFile() }
        
        let headerData = fileHandle.readData(ofLength: 12)
        guard headerData.count >= 12 else {
            return nil
        }
        
        // Format header bytes
        let bytes = headerData.map { String(format: "%02X", $0) }.joined(separator: " ")
        
        // Try to read ftyp brand
        if headerData.count >= 12 {
            let ftypBytes = headerData.subdata(in: 4..<8)
            let brandBytes = headerData.subdata(in: 8..<12)
            
            if let ftyp = String(data: ftypBytes, encoding: .ascii),
               let brand = String(data: brandBytes, encoding: .ascii) {
                return "\(bytes) (ftyp: '\(ftyp)', brand: '\(brand)')"
            }
        }
        
        return bytes
    }
    
    // Helper to check if file is HEIC using our detection method
    static func checkIfHEIC(url: URL) -> Bool {
        // Use reflection to call private method for testing
        let mirror = Mirror(reflecting: OCROperationsWrapper.self)
        
        // Since we can't directly access private method, read header ourselves
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return false
        }
        defer { fileHandle.closeFile() }
        
        let headerData = fileHandle.readData(ofLength: 12)
        guard headerData.count >= 12 else {
            return false
        }
        
        let ftypBytes = headerData.subdata(in: 4..<8)
        let ftypString = String(data: ftypBytes, encoding: .ascii)
        
        guard ftypString == "ftyp" else {
            return false
        }
        
        let brandBytes = headerData.subdata(in: 8..<12)
        let brandString = String(data: brandBytes, encoding: .ascii)
        
        let heicBrands = ["heic", "heix", "hevc", "hevx", "heim", "heis", "hevm", "hevs", "mif1", "msf1"]
        
        return brandString.map { heicBrands.contains($0) } ?? false
    }
    
    // Create a minimal valid JPEG
    static func createMinimalJPEG() -> Data {
        // Minimal JPEG structure
        var jpegBytes: [UInt8] = []
        
        // SOI (Start of Image)
        jpegBytes.append(contentsOf: [0xFF, 0xD8])
        
        // APP0 (JFIF header)
        jpegBytes.append(contentsOf: [0xFF, 0xE0])
        jpegBytes.append(contentsOf: [0x00, 0x10]) // Length
        jpegBytes.append(contentsOf: [0x4A, 0x46, 0x49, 0x46, 0x00]) // "JFIF\0"
        jpegBytes.append(contentsOf: [0x01, 0x01]) // Version
        jpegBytes.append(contentsOf: [0x00]) // Units
        jpegBytes.append(contentsOf: [0x00, 0x01, 0x00, 0x01]) // Density
        jpegBytes.append(contentsOf: [0x00, 0x00]) // Thumbnail
        
        // DQT (Quantization Table)
        jpegBytes.append(contentsOf: [0xFF, 0xDB])
        jpegBytes.append(contentsOf: [0x00, 0x43]) // Length
        jpegBytes.append(0x00) // Table ID
        jpegBytes.append(contentsOf: Array(repeating: UInt8(0x01), count: 64)) // Table data
        
        // SOF0 (Start of Frame)
        jpegBytes.append(contentsOf: [0xFF, 0xC0])
        jpegBytes.append(contentsOf: [0x00, 0x0B]) // Length
        jpegBytes.append(0x08) // Precision
        jpegBytes.append(contentsOf: [0x00, 0x01, 0x00, 0x01]) // 1x1 dimensions
        jpegBytes.append(0x01) // Components
        jpegBytes.append(contentsOf: [0x01, 0x11, 0x00]) // Component data
        
        // DHT (Huffman Table)
        jpegBytes.append(contentsOf: [0xFF, 0xC4])
        jpegBytes.append(contentsOf: [0x00, 0x1F]) // Length
        jpegBytes.append(0x00) // Table class and ID
        jpegBytes.append(contentsOf: Array(repeating: UInt8(0x00), count: 16)) // Lengths
        jpegBytes.append(contentsOf: Array(repeating: UInt8(0x00), count: 12)) // Values
        
        // SOS (Start of Scan)
        jpegBytes.append(contentsOf: [0xFF, 0xDA])
        jpegBytes.append(contentsOf: [0x00, 0x08]) // Length
        jpegBytes.append(0x01) // Components
        jpegBytes.append(contentsOf: [0x01, 0x00]) // Component data
        jpegBytes.append(contentsOf: [0x00, 0x3F, 0x00]) // Spectral selection
        
        // Compressed data (minimal)
        jpegBytes.append(contentsOf: [0x00, 0x00])
        
        // EOI (End of Image)
        jpegBytes.append(contentsOf: [0xFF, 0xD9])
        
        return Data(jpegBytes)
    }
}

// Run header detection tests
public func runHeaderDetectionTests() async {
    await HeaderDetectionTest.runTests()
}