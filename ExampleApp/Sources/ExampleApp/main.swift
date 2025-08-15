import Foundation
import NolockOCRClient

// Check for command line arguments
let args = CommandLine.arguments
let runTests = args.contains("--test") || args.contains("-t")
let runDateTest = args.contains("--date-test") || args.contains("-d")
let runWrapperTest = args.contains("--wrapper") || args.contains("-w")
let runHeaderTest = args.contains("--header") || args.contains("-h")

if runHeaderTest {
    // Run header detection tests
    Task {
        await runHeaderDetectionTests()
        exit(0)
    }
} else if runWrapperTest {
    // Run wrapper tests
    Task {
        await runWrapperTests()
        exit(0)
    }
} else if runDateTest {
    // Run date parsing test
    Task {
        await runDateParsingTest()
        exit(0)
    }
} else if runTests {
    // Run integration tests
    Task {
        await IntegrationTests.runTests()
        exit(0)
    }
} else {
    // Run example
    print("🚀 Nolock OCR Client Example")
    print("============================\n")
    print("Tip: Run with --test flag to execute integration tests")
    print("     Run with --wrapper flag to test OCROperationsWrapper\n")
    
    // Configure the API
    NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
    
    // Create a simple async context
    Task {
        print("📡 Checking service health...")
        
        do {
            let healthResponse = try await HealthAPI.healthCheck()
            print("✅ Service is healthy: \(healthResponse)")
            print("\n----------------------------")
            print("Service is ready for OCR processing!")
            print("----------------------------\n")
            
            // Example of how to process a check (commented out since we don't have a real image)
            print("Example usage:")
            print("  1. To process a check:")
            print("     let checkURL = URL(fileURLWithPath: \"/path/to/check.jpg\")")
            print("     let checkResponse = try await OCROperationsAPI.processCheckOcr(body: checkURL)")
            print("")
            print("  2. To process a receipt:")
            print("     let receiptURL = URL(fileURLWithPath: \"/path/to/receipt.jpg\")")
            print("     let receiptResponse = try await OCROperationsAPI.processReceiptOcr(body: receiptURL)")
            
        } catch {
            print("❌ Error: \(error)")
            print("\nMake sure the service is running at:")
            print("https://nolock-ocr-services-qbhx5.ondigitalocean.app")
        }
        
        exit(0)
    }
}

// Keep the program running until async task completes
RunLoop.main.run()