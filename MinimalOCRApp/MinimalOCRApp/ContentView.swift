//
//  ContentView.swift
//  MinimalOCRApp
//
//  Created by Alexander Fedin on 8/20/25.
//

import SwiftUI
import PhotosUI
import NolockOCRClient

enum OCRType: String, CaseIterable {
    case check = "Check"
    case receipt = "Receipt"
}

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var ocrResult: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var ocrType: OCRType = .check

    var body: some View {
        VStack(spacing: 20) {
            Text("OCR Test")
                .font(.largeTitle)

            // OCR Type Picker
            Picker("OCR Type", selection: $ocrType) {
                ForEach(OCRType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // Image picker button
            PhotosPicker(
                selection: $selectedItem,
                matching: .images
            ) {
                Text("Select Image")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        await processImage(data: data, type: ocrType)
                    }
                }
            }

            // Selected image preview
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
            }

            // Processing indicator
            if isProcessing {
                ProgressView("Processing...")
            }

            // Error display
            if let error = errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Error", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(10)
            }

            // Results
            if !ocrResult.isEmpty {
                ScrollView {
                    Text(ocrResult)
                        .padding()
                }
                .frame(maxHeight: 200)
                .background(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            // Configure API endpoint
            NolockOCRClientAPI.basePath = "https://nolock-ocr-services-qbhx5.ondigitalocean.app"
        }
    }

    func processImage(data: Data, type: OCRType) async {
        isProcessing = true
        ocrResult = ""
        errorMessage = nil

        do {
            switch type {
            case .check:
                let response = try await OCROperationsWrapper.processCheckOcr(imageData: data)
                if let check = response.modelData {
                    ocrResult = formatCheckResult(check)
                } else {
                    errorMessage = "No check data found in the image. Please ensure the image contains a clear check."
                }

            case .receipt:
                let response = try await OCROperationsWrapper.processReceiptOcr(imageData: data)
                if let receipt = response.modelData {
                    ocrResult = formatReceiptResult(receipt)
                } else {
                    errorMessage = "No receipt data found in the image. Please ensure the image contains a clear receipt."
                }
            }
        } catch {
            // Extract detailed error message
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    func formatCheckResult(_ check: Check) -> String {
        var resultText = "✅ Check OCR Results\n\n"

        if let amount = check.amount {
            resultText += "Amount: $\(String(format: "%.2f", amount))\n"
        }
        if let payee = check.payee, !payee.isEmpty {
            resultText += "Payee: \(payee)\n"
        }
        if let payer = check.payer, !payer.isEmpty {
            resultText += "Payer: \(payer)\n"
        }
        if let checkNumber = check.checkNumber, !checkNumber.isEmpty {
            resultText += "Check #: \(checkNumber)\n"
        }
        if let bankName = check.bankName, !bankName.isEmpty {
            resultText += "Bank: \(bankName)\n"
        }
        if let routingNumber = check.routingNumber, !routingNumber.isEmpty {
            resultText += "Routing: \(routingNumber)\n"
        }
        if let accountNumber = check.accountNumber, !accountNumber.isEmpty {
            resultText += "Account: \(accountNumber)\n"
        }
        if let date = check.date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            resultText += "Date: \(formatter.string(from: date))\n"
        }
        if let confidence = check.confidence {
            resultText += "\nConfidence: \(Int(confidence * 100))%"
        }

        return resultText
    }

    func formatReceiptResult(_ receipt: Receipt) -> String {
        var resultText = "✅ Receipt OCR Results\n\n"

        if let merchant = receipt.merchant {
            if let name = merchant.name, !name.isEmpty {
                resultText += "Merchant: \(name)\n"
            }
            if let address = merchant.address, !address.isEmpty {
                resultText += "Address: \(address)\n"
            }
        }

        if let totals = receipt.totals {
            if let subtotal = totals.subtotal {
                resultText += "\nSubtotal: $\(String(format: "%.2f", subtotal))\n"
            }
            if let tax = totals.tax {
                resultText += "Tax: $\(String(format: "%.2f", tax))\n"
            }
            if let tip = totals.tip, tip > 0 {
                resultText += "Tip: $\(String(format: "%.2f", tip))\n"
            }
            if let total = totals.total {
                resultText += "Total: $\(String(format: "%.2f", total))\n"
            }
        }

        if let items = receipt.items, !items.isEmpty {
            resultText += "\nItems (\(items.count)):\n"
            for item in items.prefix(5) {  // Show first 5 items
                if let desc = item.description {
                    resultText += "• \(desc)"
                    if let price = item.totalPrice {
                        resultText += " - $\(String(format: "%.2f", price))"
                    }
                    resultText += "\n"
                }
            }
            if items.count > 5 {
                resultText += "... and \(items.count - 5) more items\n"
            }
        }

        if let timestamp = receipt.timestamp {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            resultText += "\nDate/Time: \(formatter.string(from: timestamp))"
        }

        if let confidence = receipt.confidence {
            resultText += "\nConfidence: \(Int(confidence * 100))%"
        }

        return resultText
    }

    func extractErrorMessage(from error: Error) -> String {
        // The SDK now provides user-friendly messages directly
        return error.localizedDescription
    }
}

#Preview {
    ContentView()
}