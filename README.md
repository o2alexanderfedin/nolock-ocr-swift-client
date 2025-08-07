# Nolock OCR Swift Client

Swift client library for Nolock OCR Services API, providing check and receipt OCR capabilities.

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
        let imageData = Data() // Your check image data
        let response = try await OCROperationsAPI.processCheckImage(body: imageData)
        
        if let check = response.body {
            print("Account Number: \(check.accountNumber ?? "")")
            print("Routing Number: \(check.routingNumber ?? "")")
            print("Check Number: \(check.checkNumber ?? "")")
            print("Amount: \(check.amount ?? 0)")
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
        let imageData = Data() // Your receipt image data
        let response = try await OCROperationsAPI.processReceiptImage(body: imageData)
        
        if let receipt = response.body {
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

### Using Completion Handlers

```swift
// Process check with completion handler
OCROperationsAPI.processCheckImage(body: imageData) { result in
    switch result {
    case .success(let response):
        if let check = response.body {
            // Handle check data
        }
    case .failure(let error):
        print("Error: \(error)")
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

- `POST /api/ocr/check` - Process check image
- `POST /api/ocr/receipt` - Process receipt image
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

## License

This client library is auto-generated from the OpenAPI specification.

## Support

For API issues, please contact the Nolock OCR Services team.
For client library issues, please open an issue on GitHub.