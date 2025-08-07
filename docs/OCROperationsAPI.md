# OCROperationsAPI

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**processCheckOcr**](OCROperationsAPI.md#processcheckocr) | **POST** /ocr/checks | Process check image with OCR and extract structured data
[**processReceiptOcr**](OCROperationsAPI.md#processreceiptocr) | **POST** /ocr/receipts | Process receipt image with OCR and extract structured data


# **processCheckOcr**
```swift
    open class func processCheckOcr(body: URL, completion: @escaping (_ data: CheckModelOcrResponse?, _ error: Error?) -> Void)
```

Process check image with OCR and extract structured data

Processes a check image using Mistral OCR and extracts structured check data including amount, payee, payer, bank info, and routing details.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import NolockOCRClient

let body = URL(string: "https://example.com")! // URL | 

// Process check image with OCR and extract structured data
OCROperationsAPI.processCheckOcr(body: body) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **body** | **URL** |  | 

### Return type

[**CheckModelOcrResponse**](CheckModelOcrResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/octet-stream, image/jpeg, image/png, image/gif, image/bmp, image/webp, image/tiff
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **processReceiptOcr**
```swift
    open class func processReceiptOcr(body: URL, completion: @escaping (_ data: ReceiptModelOcrResponse?, _ error: Error?) -> Void)
```

Process receipt image with OCR and extract structured data

Processes a receipt image using Mistral OCR and extracts structured receipt data including merchant info, totals, items, and payment details.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import NolockOCRClient

let body = URL(string: "https://example.com")! // URL | 

// Process receipt image with OCR and extract structured data
OCROperationsAPI.processReceiptOcr(body: body) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **body** | **URL** |  | 

### Return type

[**ReceiptModelOcrResponse**](ReceiptModelOcrResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/octet-stream, image/jpeg, image/png, image/gif, image/bmp, image/webp, image/tiff
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

