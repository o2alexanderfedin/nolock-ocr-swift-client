import Foundation

// MARK: - Authenticated Request Builder Factory

public class AuthenticatedRequestBuilderFactory: RequestBuilderFactory {
    internal let tokenProvider: TokenProvider

    public init(tokenProvider: TokenProvider) {
        self.tokenProvider = tokenProvider
    }

    public func getNonDecodableBuilder<T>() -> RequestBuilder<T>.Type {
        return AuthenticatedURLSessionRequestBuilder<T>.self
    }

    public func getBuilder<T: Decodable>() -> RequestBuilder<T>.Type {
        return AuthenticatedDecodableRequestBuilder<T>.self
    }
}

// MARK: - Authenticated URL Session Request Builder

class AuthenticatedURLSessionRequestBuilder<T>: URLSessionRequestBuilder<T> {

    required init(method: String, URLString: String, parameters: [String: Any]?, headers: [String: String]) {
        super.init(method: method, URLString: URLString, parameters: parameters, headers: headers)
    }

    @discardableResult
    override func execute(_ apiResponseQueue: DispatchQueue = NolockOCRClientAPI.apiResponseQueue,
                          _ completion: @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void) -> RequestTask {

        // Get the token provider from the factory
        guard let factory = NolockOCRClientAPI.requestBuilderFactory as? AuthenticatedRequestBuilderFactory else {
            return super.execute(apiResponseQueue, completion)
        }

        // Add auth header
        if #available(iOS 13.0, macOS 10.15, *) {
            Task {
                do {
                    let token = try await factory.tokenProvider.getToken()
                    self.headers["Authorization"] = "Bearer \(token)"
                } catch {
                    // Can't get token, proceed anyway
                }
                _ = super.execute(apiResponseQueue, completion)
            }
            return requestTask
        } else {
            return super.execute(apiResponseQueue, completion)
        }
    }

}

// MARK: - Authenticated Decodable Request Builder

class AuthenticatedDecodableRequestBuilder<T: Decodable>: AuthenticatedURLSessionRequestBuilder<T> {
    @discardableResult
    override func execute(_ apiResponseQueue: DispatchQueue = NolockOCRClientAPI.apiResponseQueue,
                          _ completion: @escaping (_ result: Swift.Result<Response<T>, ErrorResponse>) -> Void) -> RequestTask {
        return super.execute(apiResponseQueue, completion)
    }
}