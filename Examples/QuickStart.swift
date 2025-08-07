import Foundation
import NolockOCRClient

// MARK: - Quick Start Example

class NolockOCRExample {
    
    init() {
        // Configure the API base path
        NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
    }
    
    // MARK: - Check Processing
    
    func processCheck(imageData: Data) async throws -> Check? {
        do {
            let response = try await OCROperationsAPI.processCheckImage(body: imageData)
            
            if let check = response.body {
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
    
    // MARK: - Receipt Processing
    
    func processReceipt(imageData: Data) async throws -> Receipt? {
        do {
            let response = try await OCROperationsAPI.processReceiptImage(body: imageData)
            
            if let receipt = response.body {
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
        
        // Process a check image
        if let checkImageData = loadImageData(named: "check.jpg") {
            _ = try? await client.processCheck(imageData: checkImageData)
        }
        
        // Process a receipt image
        if let receiptImageData = loadImageData(named: "receipt.jpg") {
            _ = try? await client.processReceipt(imageData: receiptImageData)
        }
    }
}

// Helper function to load image data
func loadImageData(named: String) -> Data? {
    // In a real app, load image from bundle or file system
    return nil
}