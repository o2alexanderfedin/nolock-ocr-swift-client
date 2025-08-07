import Foundation
import NolockOCRClient

// MARK: - Quick Start Example

class NolockOCRExample {
    
    init() {
        // Configure the API base path
        NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
    }
    
    // MARK: - Check Processing
    
    func processCheck(imageURL: URL) async throws -> Check? {
        do {
            let response = try await OCROperationsAPI.processCheckOcr(body: imageURL)
            
            if let check = response.modelData {
                print("✅ Check processed successfully")
                print("Account Number: \(check.accountNumber ?? "N/A")")
                print("Routing Number: \(check.routingNumber ?? "N/A")")
                print("Check Number: \(check.checkNumber ?? "N/A")")
                print("Amount: $\(check.amount ?? 0)")
                print("Date: \(check.date ?? "N/A")")
                print("Payee: \(check.payeeName ?? "N/A")")
                
                return check
            }
            
            return nil
        } catch {
            print("❌ Error processing check: \(error)")
            throw error
        }
    }
    
    // MARK: - Check Processing with Data
    
    func processCheckData(imageData: Data) async throws -> Check? {
        // Save data to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        
        try imageData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        return try await processCheck(imageURL: tempURL)
    }
    
    // MARK: - Receipt Processing
    
    func processReceipt(imageURL: URL) async throws -> Receipt? {
        do {
            let response = try await OCROperationsAPI.processReceiptOcr(body: imageURL)
            
            if let receipt = response.modelData {
                print("✅ Receipt processed successfully")
                
                // Merchant info
                if let merchant = receipt.merchantInfo {
                    print("Merchant: \(merchant.name ?? "N/A")")
                    print("Address: \(merchant.address ?? "N/A")")
                    print("Phone: \(merchant.phone ?? "N/A")")
                }
                
                // Line items
                if let items = receipt.lineItems {
                    print("\nItems:")
                    for item in items {
                        print("  - \(item.description ?? "Unknown") x\(item.quantity ?? 1) = $\(item.totalPrice ?? 0)")
                    }
                }
                
                // Totals
                if let totals = receipt.totals {
                    print("\nTotals:")
                    print("  Subtotal: $\(totals.subtotal ?? 0)")
                    print("  Tax: $\(totals.tax ?? 0)")
                    print("  Total: $\(totals.total ?? 0)")
                }
                
                return receipt
            }
            
            return nil
        } catch {
            print("❌ Error processing receipt: \(error)")
            throw error
        }
    }
    
    // MARK: - Receipt Processing with Data
    
    func processReceiptData(imageData: Data) async throws -> Receipt? {
        // Save data to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        
        try imageData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        return try await processReceipt(imageURL: tempURL)
    }
    
    // MARK: - Health Check
    
    func checkHealth() async -> Bool {
        do {
            _ = try await HealthAPI.healthGet()
            print("✅ Service is healthy")
            return true
        } catch {
            print("❌ Service health check failed: \(error)")
            return false
        }
    }
}

// MARK: - Usage Example

func exampleUsage() {
    let client = NolockOCRExample()
    
    Task {
        // Check service health
        let isHealthy = await client.checkHealth()
        guard isHealthy else {
            print("Service is not available")
            return
        }
        
        // Process a check image from file
        let checkURL = URL(fileURLWithPath: "/path/to/check.jpg")
        if FileManager.default.fileExists(atPath: checkURL.path) {
            _ = try? await client.processCheck(imageURL: checkURL)
        }
        
        // Process a receipt image from data
        if let receiptImageData = loadImageData(named: "receipt.jpg") {
            _ = try? await client.processReceiptData(imageData: receiptImageData)
        }
    }
}

// Helper function to load image data
func loadImageData(named: String) -> Data? {
    // In a real app, load image from bundle or file system
    return nil
}