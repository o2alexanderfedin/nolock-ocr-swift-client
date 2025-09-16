# NolockOCRClient Authentication Guide

## Overview

The NolockOCRClient now includes automatic authentication header handling for all OCR API calls. This feature transparently manages Apple JWS (JSON Web Signature) tokens from StoreKit 2 subscriptions, making it simple for developers to integrate authenticated OCR services without manual token management.

## Features

- **Automatic Header Injection**: Authorization headers are automatically added to all OCR API requests
- **StoreKit 2 Integration**: Seamlessly extracts JWS tokens from active subscriptions
- **Token Caching**: Intelligent caching reduces StoreKit queries
- **Automatic Token Refresh**: Expired tokens are automatically refreshed
- **Mock Authentication**: Built-in mock provider for testing and development
- **Custom Providers**: Support for custom authentication implementations

## Quick Start

### 1. StoreKit Authentication (Production)

For production iOS apps with StoreKit subscriptions:

```swift
import NolockOCRClient

// Configure StoreKit authentication at app launch
if #available(iOS 15.0, *) {
    NolockOCRClientAPI.configureStoreKitAuthentication(
        productIdentifiers: ["com.yourapp.premium"], // Optional: specific product IDs
        configuration: .default
    )
}

// That's it! All OCR calls will now include authentication
let response = try await OCROperationsAPI.processCheckOcr(body: imageURL)
```

### 2. Mock Authentication (Development/Testing)

For development and testing without requiring actual subscriptions:

```swift
import NolockOCRClient

// Configure mock authentication for testing
NolockOCRClientAPI.configureMockAuthentication(
    mockToken: "test-jwt-token-12345"
)

// Make OCR calls as usual - mock token will be included
let response = try await OCROperationsAPI.processReceiptOcr(body: imageURL)
```

### 3. Custom Authentication Provider

For custom authentication implementations:

```swift
import NolockOCRClient

// Create your custom provider
class CustomAuthProvider: AuthenticationProvider {
    func getCurrentToken() async throws -> String {
        // Your token fetching logic
        return "custom-jwt-token"
    }

    func refreshToken() async throws -> String {
        // Your token refresh logic
        return "refreshed-jwt-token"
    }

    func isTokenValid() async throws -> Bool {
        // Your validation logic
        return true
    }
}

// Configure the client with your provider
let customProvider = CustomAuthProvider()
NolockOCRClientAPI.configureAuthentication(
    provider: customProvider,
    configuration: .default
)
```

## Configuration Options

### Authentication Configuration

Customize authentication behavior with `AuthenticationConfiguration`:

```swift
let config = AuthenticationConfiguration(
    automaticTokenRefresh: true,      // Automatically refresh expired tokens
    tokenRefreshBuffer: 300,          // Refresh 5 minutes before expiration
    maxRetryAttempts: 3,              // Max retry attempts on 401
    retryDelay: 1.0                   // Delay between retries (seconds)
)

NolockOCRClientAPI.configureStoreKitAuthentication(
    configuration: config
)
```

### Product Identifier Filtering

Optionally specify which subscription products to use for authentication:

```swift
NolockOCRClientAPI.configureStoreKitAuthentication(
    productIdentifiers: [
        "com.yourapp.monthly",
        "com.yourapp.yearly"
    ]
)
```

If no product identifiers are specified, the provider will use any active subscription.

## Advanced Usage

### Manual Token Management

If you need direct control over tokens:

```swift
// Get the current token
let token = try await AuthenticationManager.shared.getToken()

// Manually refresh the token
let newToken = try await AuthenticationManager.shared.refreshToken()

// Clear cached tokens
NolockOCRClientAPI.clearAuthenticationCache()
```

### Disable Authentication

To disable authentication temporarily:

```swift
// Disable authentication
NolockOCRClientAPI.disableAuthentication()

// Re-enable later
NolockOCRClientAPI.configureStoreKitAuthentication()
```

### Error Handling

Handle authentication-specific errors:

```swift
do {
    let response = try await OCROperationsAPI.processCheckOcr(body: imageURL)
} catch AuthenticationError.noActiveSubscription {
    // Handle no subscription
    print("Please subscribe to use OCR features")
} catch AuthenticationError.tokenExpired {
    // Handle expired token (rare - usually auto-refreshed)
    print("Authentication expired, please try again")
} catch {
    // Handle other errors
    print("Error: \(error)")
}
```

## Testing

### Unit Tests with Mock Provider

```swift
func testOCRWithMockAuthentication() async throws {
    // Create mock provider
    let mockProvider = MockAuthenticationProvider()
    mockProvider.configureValidToken(expiresIn: 3600)

    // Configure client
    NolockOCRClientAPI.configureAuthentication(provider: mockProvider)

    // Test OCR calls
    let response = try await OCROperationsAPI.processCheckOcr(body: testImageURL)

    // Verify authentication was used
    XCTAssertGreaterThan(mockProvider.getCurrentTokenCallCount, 0)
}
```

### Testing Token Expiration

```swift
func testTokenRefresh() async throws {
    let mockProvider = MockAuthenticationProvider()
    mockProvider.simulateExpiredToken()

    NolockOCRClientAPI.configureAuthentication(
        provider: mockProvider,
        configuration: AuthenticationConfiguration(
            automaticTokenRefresh: true
        )
    )

    // Make request - should auto-refresh
    _ = try await OCROperationsAPI.processReceiptOcr(body: testImageURL)

    // Verify refresh occurred
    XCTAssertEqual(mockProvider.refreshTokenCallCount, 1)
}
```

## Migration Guide

### From Manual Authentication

If you were previously adding headers manually:

**Before:**
```swift
// Manual header management
var headers = ["Authorization": "Bearer \(getToken())"]
let request = OCROperationsAPI.processCheckOcrWithRequestBuilder(body: imageURL)
request.addHeaders(headers)
let response = try await request.execute()
```

**After:**
```swift
// Automatic authentication
NolockOCRClientAPI.configureStoreKitAuthentication()
let response = try await OCROperationsAPI.processCheckOcr(body: imageURL)
```

### From No Authentication

If you were using the client without authentication:

1. Add StoreKit capability to your app (if using StoreKit authentication)
2. Configure authentication at app launch
3. No changes needed to existing OCR calls

## Best Practices

1. **Configure Once**: Set up authentication once at app launch, not before each request
2. **Use StoreKit for Production**: Use `configureStoreKitAuthentication` for production iOS apps
3. **Use Mock for Development**: Use `configureMockAuthentication` during development
4. **Handle Errors Gracefully**: Always handle `noActiveSubscription` error for better UX
5. **Test Token Expiration**: Test token refresh scenarios in your test suite

## Troubleshooting

### No Authorization Header in Requests

- Verify authentication is configured: `NolockOCRClientAPI.configureStoreKitAuthentication()`
- Check if subscription is active (StoreKit)
- Ensure mock token is set (Mock provider)

### 401 Unauthorized Errors

- Verify token is valid and not expired
- Check subscription status in StoreKit
- Ensure correct product identifiers are specified

### Token Not Refreshing

- Check `automaticTokenRefresh` is enabled in configuration
- Verify `refreshToken()` implementation in custom providers
- Check network connectivity

## Support

For issues or questions about authentication:
1. Check error messages for specific authentication problems
2. Enable debug logging to see token fetch/refresh events
3. Use mock provider to isolate authentication issues
4. Contact support with authentication configuration details