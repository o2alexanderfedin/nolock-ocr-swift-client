//
//  ContentView.swift
//  MinimalOCRApp
//
//  Created by Alexander Fedin on 8/20/25.
//

import SwiftUI
import PhotosUI
import NolockOCRClient

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var ocrResult: String = ""
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("OCR Test")
                .font(.largeTitle)
            
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
                        await processImage(data: data)
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
            
            // Results
            if !ocrResult.isEmpty {
                ScrollView {
                    Text(ocrResult)
                        .padding()
                }
                .frame(maxHeight: 200)
                .background(Color.gray.opacity(0.1))
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
    
    func processImage(data: Data) async {
        isProcessing = true
        ocrResult = ""
        
        do {
            let response = try await OCROperationsWrapper.processCheckOcr(imageData: data)
            
            if let check = response.modelData {
                ocrResult = """
                ✅ OCR Success!
                Amount: \(check.amount ?? 0)
                Payee: \(check.payee ?? "N/A")
                Date: \(check.date?.description ?? "N/A")
                Check #: \(check.checkNumber ?? "N/A")
                """
            } else {
                ocrResult = "No data found in image"
            }
        } catch {
            ocrResult = "❌ Error: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
}

#Preview {
    ContentView()
}