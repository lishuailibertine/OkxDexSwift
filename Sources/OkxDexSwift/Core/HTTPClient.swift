import Foundation
import CryptoSwift
public enum APIError: Error {
    case invalidURL
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case apiError(code: String, message: String)
    case unknown(Error)
}

public class HTTPClient {
    private let config: OKXConfig
    private let session: URLSession
    
    public init(config: OKXConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }
    
    public func request<T: Codable>(
        method: String,
        path: String,
        params: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> T {
        guard let url = URL(string: config.baseUrl + path) else {
            throw APIError.invalidURL
        }
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        var queryString = ""
        if let params = params, !params.isEmpty {
            urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            queryString = "?" + (urlComponents.percentEncodedQuery ?? "")
        }
        
        guard let finalUrl = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: finalUrl)
        request.httpMethod = method
        request.httpBody = body
        
        let timestamp = ISO8601DateFormatter.string(from: Date(), timeZone: TimeZone(secondsFromGMT: 0)!, formatOptions: [.withInternetDateTime, .withFractionalSeconds])
        
        // Sign request
        let bodyString = body != nil ? String(data: body!, encoding: .utf8) ?? "" : ""
        let stringToSign = timestamp + method + path + queryString + bodyString
        
        let secret = config.secretKey.data(using: .utf8)!
        let signature = try HMAC(key: secret.byteArray, variant: .sha2(.sha256)).authenticate(Array(stringToSign.utf8))
        let signatureBase64 = Data(signature).base64EncodedString()
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "OK-ACCESS-KEY")
        request.setValue(signatureBase64, forHTTPHeaderField: "OK-ACCESS-SIGN")
        request.setValue(timestamp, forHTTPHeaderField: "OK-ACCESS-TIMESTAMP")
        request.setValue(config.apiPassphrase, forHTTPHeaderField: "OK-ACCESS-PASSPHRASE")
        request.setValue(config.projectId, forHTTPHeaderField: "OK-ACCESS-PROJECT")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(NSError(domain: "InvalidResponse", code: 0, userInfo: nil))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
