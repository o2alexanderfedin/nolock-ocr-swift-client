// Minimal iOS app - just test OCR
// To use: Add this file to any iOS Xcode project

import UIKit
import NolockOCRClient

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let button = UIButton(frame: CGRect(x: 100, y: 200, width: 200, height: 50))
        button.setTitle("Test OCR", for: .normal)
        button.backgroundColor = .blue
        button.addTarget(self, action: #selector(testOCR), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func testOCR() {
        print("Testing OCR...")
        
        // Set API endpoint
        NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
        
        Task {
            do {
                // Create test image data
                let image = UIImage()
                let imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
                
                // Call OCR
                let response = try await OCROperationsWrapper.processCheckOcr(imageData: imageData)
                print("✅ OCR Success: \(response)")
            } catch {
                print("❌ OCR Error: \(error)")
            }
        }
    }
}