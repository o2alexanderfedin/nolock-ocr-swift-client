# HealthAPI

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthCheck**](HealthAPI.md#healthcheck) | **GET** /health | Health check endpoint


# **healthCheck**
```swift
    open class func healthCheck(completion: @escaping (_ data: AnyCodable?, _ error: Error?) -> Void)
```

Health check endpoint

Returns the health status of the service

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import NolockOCRClient


// Health check endpoint
HealthAPI.healthCheck() { (response, error) in
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
This endpoint does not need any parameter.

### Return type

**AnyCodable**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

