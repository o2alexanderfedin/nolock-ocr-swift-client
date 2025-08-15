# Nolock OCR Swift Client Integration Guide

## Part 1: Building and Running the Example App

### Prerequisites
- macOS 13.0 or later
- Xcode 14.0 or later
- Swift 5.9 or later
- Internet connection (for API calls)

### Step-by-Step Build Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/o2alexanderfedin/nolock-ocr-swift-client.git
   cd nolock-ocr-swift-client
   ```

2. **Build the Project**
   ```bash
   swift build
   ```

3. **Run the Example App**
   ```bash
   # Basic run (shows usage instructions)
   swift run ExampleApp
   
   # Run all tests to verify everything works
   swift run ExampleApp --test
   ```

4. **Expected Output**
   If successful, you should see:
   - ✅ Service is healthy
   - ✅ All test suites completed successfully

### Troubleshooting
- If build fails: Check Swift version with `swift --version`
- If tests fail: Ensure internet connection is active
- If hanging: Use `timeout 10 swift run ExampleApp --test`

---

## Part 2: iOS App Integration

### Installation

#### Option 1: Swift Package Manager (Recommended)
1. In Xcode, select **File → Add Package Dependencies**
2. Enter: `https://github.com/o2alexanderfedin/nolock-ocr-swift-client.git`
3. Select version: **1.5.0** or later
4. Add to your target

#### Option 2: CocoaPods
```ruby
pod 'NolockOCRClient', '~> 1.5'
```

### Updating to Latest Version

Swift Package Manager caches package dependencies locally. When a new version is released, you need to explicitly update to get the latest changes.

#### Updating Swift Package Dependencies in Xcode

1. **Update Package to Latest Version**
   - Open your project in Xcode
   - Select your project in the navigator
   - Select your project (not target) in the editor
   - Click **Package Dependencies** tab
   - Right-click on `nolock-ocr-swift-client`
   - Select **Update to Latest Package Versions**

2. **Force Reset Package Cache (if needed)**
   - File → Packages → **Reset Package Caches**
   - This forces Xcode to re-download all packages
   - Useful when updates don't appear immediately

3. **Command Line Alternative**
   ```bash
   # In your project directory
   swift package update
   ```

4. **Update Specific Package Version**
   - Double-click the package in Package Dependencies
   - Change version rule to exact version (e.g., "1.5.2")
   - Or use branch-based rule for development

#### Updating CocoaPods Dependencies

```bash
# Update pod repo
pod repo update

# Update specific pod
pod update NolockOCRClient

# Or update all pods
pod update
```

#### Verify Current Version

```swift
// Add this temporarily to verify the version in use
print("NolockOCRClient version: check Package.resolved or Podfile.lock")
```

**Important**: After updating, clean build folder (Shift+Cmd+K) and rebuild to ensure no cached modules are used.

### Basic Integration

#### 1. Configure the API (AppDelegate or SceneDelegate)
```swift
import NolockOCRClient

// In application(_:didFinishLaunchingWithOptions:)
NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
```

#### 2. Simple Check OCR Implementation
```swift
import NolockOCRClient
import UIKit

class CheckScannerViewController: UIViewController {
    
    func processCheck(imageURL: URL) async {
        do {
            // OCROperationsWrapper handles ALL conversions automatically
            // Works with HEIC, JPEG, PNG - any image format
            let response = try await OCROperationsWrapper.processCheckOcr(imageURL: imageURL)
            
            // Use the data
            if let check = response.modelData {
                print("Amount: $\(check.amount ?? 0)")
                print("Payee: \(check.payee ?? "Unknown")")
            }
        } catch {
            print("OCR failed: \(error)")
        }
    }
}
```

#### 3. Camera Integration with HEIC Support
```swift
import UIKit
import NolockOCRClient

class CameraViewController: UIViewController {
    
    @IBAction func capturePhoto(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, 
                              didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        // Get image URL - OCROperationsWrapper handles ANY format (HEIC, JPEG, PNG)
        if let imageURL = info[.imageURL] as? URL {
            Task {
                do {
                    // Direct processing - no conversion needed!
                    let response = try await OCROperationsWrapper.processCheckOcr(imageURL: imageURL)
                    
                    await MainActor.run {
                        if let check = response.modelData {
                            print("Amount: $\(check.amount ?? 0)")
                        }
                    }
                } catch {
                    print("Error: \(error)")
                }
            }
        }
    }
}
```

#### 4. SwiftUI Implementation
```swift
import SwiftUI
import NolockOCRClient

struct OCRView: View {
    @State private var amount: Double = 0
    @State private var payee: String = ""
    @State private var isProcessing = false
    
    var body: some View {
        VStack {
            if isProcessing {
                ProgressView("Processing...")
            } else {
                Text("Amount: $\(amount, specifier: "%.2f")")
                Text("Payee: \(payee)")
                
                Button("Scan Check") {
                    Task {
                        await scanCheck()
                    }
                }
            }
        }
    }
    
    func scanCheck() async {
        isProcessing = true
        defer { isProcessing = false }
        
        // Get image URL from camera/gallery
        guard let imageURL = getImageURL() else { return }
        
        do {
            let response = try await OCROperationsWrapper.processCheckOcr(imageURL: imageURL)
            
            if let check = response.modelData {
                amount = check.amount ?? 0
                payee = check.payee ?? ""
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func getImageURL() -> URL? {
        // Implementation depends on your image source
        return nil
    }
}
```

### Best Practices

#### 1. Error Handling
```swift
enum OCRError: LocalizedError {
    case imageProcessingFailed
    case networkError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed: return "Failed to process image"
        case .networkError: return "Network connection failed"
        case .invalidResponse: return "Invalid response from server"
        }
    }
}

func processWithErrorHandling(url: URL) async throws {
    do {
        let response = try await OCROperationsWrapper.processCheckOcr(imageURL: url)
        guard response.success == true else {
            throw OCRError.invalidResponse
        }
        // Process response
    } catch {
        // Handle specific errors
        throw OCRError.networkError
    }
}
```

#### 2. Automatic Cleanup
```swift
// OCROperationsWrapper handles cleanup automatically!
// No configuration needed - wrapper always cleans up temp files

func processImage(imageURL: URL) async {
    do {
        let response = try await OCROperationsWrapper.processCheckOcr(imageURL: imageURL)
        // Use response - no manual cleanup needed
    } catch {
        print("Error: \(error)")
    }
}
```


### Testing Your Integration

1. **Create a Test Image**
   ```swift
   func testOCRIntegration() async {
       // Use bundled test image
       guard let testURL = Bundle.main.url(forResource: "test-check", withExtension: "jpg") else {
           XCTFail("Test image not found")
           return
       }
       
       do {
           let response = try await OCROperationsWrapper.processCheckOcr(imageURL: testURL)
           XCTAssertNotNil(response.modelData)
       } catch {
           XCTFail("OCR failed: \(error)")
       }
   }
   ```

2. **Mock for UI Testing**
   ```swift
   #if DEBUG
   extension OCROperationsWrapper {
       static func mockResponse() -> CheckModelOcrResponse {
           let check = Check(
               amount: 123.45,
               payee: "Test Payee",
               date: Date()
           )
           return CheckModelOcrResponse(
               success: true,
               modelData: check
           )
       }
   }
   #endif
   ```

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| HEIC images not converting | Wrapper handles automatically, ensure using `OCROperationsWrapper` not direct API |
| Memory warnings | Process smaller batches or implement pagination |
| Slow processing | Process images in background queue |
| Network timeouts | Implement retry logic with exponential backoff |

### Minimal Complete Example

```swift
import UIKit
import NolockOCRClient

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
    }
    
    @IBAction func scanTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,
                              didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        
        guard let url = info[.imageURL] as? URL else { return }
        
        Task {
            do {
                // That's it! OCROperationsWrapper handles EVERYTHING:
                // - HEIC to JPEG conversion if needed
                // - Image processing
                // - Temporary file cleanup
                let response = try await OCROperationsWrapper.processCheckOcr(imageURL: url)
                print("Amount: $\(response.modelData?.amount ?? 0)")
            } catch {
                print("Error: \(error)")
            }
        }
    }
}
```

### Support

- **Documentation**: Check the README.md for API details
- **Issues**: Report at https://github.com/o2alexanderfedin/nolock-ocr-swift-client/issues
- **Tests**: Run `swift test` to verify integration

---

## Summary

The OCROperationsWrapper provides:
- ✅ Automatic HEIC to JPEG conversion (95% quality)
- ✅ Automatic temporary file cleanup
- ✅ Simple async/await API
- ✅ Memory-efficient processing
- ✅ Cross-platform support (iOS 13+, macOS 10.15+)

Follow the KISS principle: Start with the minimal example and add features as needed.