# Nolock OCR Swift Client

Swift client library for Nolock OCR Services API, providing check and receipt OCR capabilities.

## 🔗 Related Repositories

- **Backend Service**: https://github.com/nolock-social/ocr-backend
- **Live API**: https://nolock-ocr-services-qbhx5.ondigitalocean.app
- **API Documentation**: https://nolock-ocr-services-qbhx5.ondigitalocean.app/swagger

## Features

- 📷 Check OCR processing
- 🧾 Receipt OCR processing  
- 🔄 Async/await support
- 📦 Swift Package Manager compatible
- 🏗️ Type-safe API client

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/o2alexanderfedin/nolock-ocr-swift-client.git", from: "1.0.0")
]
```

## Usage

### Initialize Client

```swift
import NolockOCRClient

// Set the base URL for the API
NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
```

### Process Check Image

```swift
// Using async/await
Task {
    do {
        // Note: The API expects a URL to a local image file
        let imageURL = URL(fileURLWithPath: "/path/to/check.jpg")
        let response = try await OCROperationsAPI.processCheckOcr(body: imageURL)
        
        if let check = response.modelData {
            print("Account Number: \(check.accountNumber ?? "")")
            print("Routing Number: \(check.routingNumber ?? "")")
            print("Check Number: \(check.checkNumber ?? "")")
            print("Amount: \(check.amount ?? 0)")
            print("Date: \(check.date ?? "")")
            print("Payee: \(check.payeeName ?? "")")
        }
    } catch {
        print("Error processing check: \(error)")
    }
}
```

### Process Receipt Image

```swift
// Using async/await
Task {
    do {
        // Note: The API expects a URL to a local image file
        let imageURL = URL(fileURLWithPath: "/path/to/receipt.jpg")
        let response = try await OCROperationsAPI.processReceiptOcr(body: imageURL)
        
        if let receipt = response.modelData {
            print("Merchant: \(receipt.merchantInfo?.name ?? "")")
            print("Total: \(receipt.totals?.total ?? 0)")
            print("Date: \(receipt.transactionDate ?? "")")
            
            // Process line items
            for item in receipt.lineItems ?? [] {
                print("Item: \(item.description ?? "") - \(item.totalPrice ?? 0)")
            }
        }
    } catch {
        print("Error processing receipt: \(error)")
    }
}
```

### Alternative: Using Data Instead of URL

If you have image data in memory, you can save it to a temporary file first:

```swift
func processImageData(_ imageData: Data, isReceipt: Bool) async throws {
    // Save data to temporary file
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("jpg")
    
    try imageData.write(to: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }
    
    // Process the image
    if isReceipt {
        let response = try await OCROperationsAPI.processReceiptOcr(body: tempURL)
        // Handle receipt response...
    } else {
        let response = try await OCROperationsAPI.processCheckOcr(body: tempURL)
        // Handle check response...
    }
}
```

### Health Check

```swift
Task {
    do {
        let response = try await HealthAPI.healthGet()
        print("Service Status: \(response)")
    } catch {
        print("Health check failed: \(error)")
    }
}
```

## API Endpoints

- `POST /ocr/checks` - Process check image
- `POST /ocr/receipts` - Process receipt image
- `GET /health` - Health check endpoint

## Models

### Check
- Account number, routing number, check number
- Amount, date, payee information
- Check type and metadata

### Receipt
- Merchant information
- Line items with prices
- Tax details and totals
- Payment method

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.5+
- Xcode 13.0+

## 🔧 Backend Development

To run the backend service locally or contribute to it:
- Repository: https://github.com/nolock-social/ocr-backend
- Technologies: .NET 9.0, Mistral AI, Cloudflare AI
- Deployment: DigitalOcean App Platform

## License

This client library is auto-generated from the OpenAPI specification.

## Support

- **Client Library Issues**: https://github.com/o2alexanderfedin/nolock-ocr-swift-client/issues
- **API/Backend Issues**: https://github.com/nolock-social/ocr-backend/issues
- **API Documentation**: https://nolock-ocr-services-qbhx5.ondigitalocean.app/swagger