//
//  HTTPClient.swift
//  1AIMoodBoardPhotoApp
//

import Foundation

enum AIError: LocalizedError {
    case invalidAPIKey
    case invalidURL
    case invalidResponse(statusCode: Int, body: String?)
    case decodingFailed(String)
    case network(Error)
    case missingDownloadURL
    case missingTaskID
    case predictionFailed(String)
    case timeout
    case emptyOutputs
    case mockFailure(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey: return "Missing or invalid API key."
        case .invalidURL: return "Invalid URL."
        case .invalidResponse(let code, let body): return "HTTP \(code): \(body ?? "")"
        case .decodingFailed(let detail): return "Decoding failed: \(detail)"
        case .network(let error): return error.localizedDescription
        case .missingDownloadURL: return "Upload did not return a download URL."
        case .missingTaskID: return "No task id from server."
        case .predictionFailed(let s): return s.isEmpty ? "Generation was rejected." : s
        case .timeout: return "Request timed out."
        case .emptyOutputs: return "No image output from AI."
        case .mockFailure(let s): return s
        }
    }
}

struct HTTPClient: Sendable {
    private let session: URLSession
    private let apiKey: String

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    private func authorizedRequest(url: URL, method: String, body: Data? = nil, contentType: String? = "application/json") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        if let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        request.httpBody = body
        request.timeoutInterval = 120
        return request
    }

    func getData(_ url: URL) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 120
        return try await session.dataWithResponse(request)
    }

    /// Public CDN URLs (no `Authorization`). Long per-request + resource timeouts and retries on `-1001` (chunk stalls).
    func getPublicBinary(url: URL) async throws -> Data {
        let maxAttempts = Constants.outputDownloadMaxAttempts
        for attempt in 1 ... maxAttempts {
            do {
                return try await getPublicBinarySingleAttempt(url: url)
            } catch let error as AIError {
                throw error
            } catch let error as URLError where error.code == .timedOut && attempt < maxAttempts {
                print("[HTTPClient] getPublicBinary timed out (attempt \(attempt)/\(maxAttempts)), retrying…")
                try await Task.sleep(nanoseconds: UInt64(1_500_000_000 * UInt64(attempt)))
            } catch {
                print("[HTTPClient] getPublicBinary error: \(error)")
                throw AIError.network(error)
            }
        }
        throw AIError.network(URLError(.timedOut))
    }

    private func getPublicBinarySingleAttempt(url: URL) async throws -> Data {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.outputDownloadRequestTimeoutSeconds
        config.timeoutIntervalForResource = Constants.outputDownloadResourceTimeoutSeconds
        let downloadSession = URLSession(configuration: config)

        var request = URLRequest(url: url)
        request.timeoutInterval = Constants.outputDownloadRequestTimeoutSeconds

        let (data, response) = try await downloadSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIError.invalidResponse(statusCode: -1, body: nil)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let body = String(data: data.prefix(800), encoding: .utf8)
            throw AIError.invalidResponse(statusCode: http.statusCode, body: body)
        }
        return data
    }

    /// Authenticated GET returning raw JSON/data (e.g. `/predictions/{id}/result`).
    func getAuthorizedData(url: URL) async throws -> Data {
        let request = authorizedRequest(url: url, method: "GET", body: nil, contentType: nil)
        do {
            let (data, response) = try await session.dataWithResponse(request)
            try validate(response: response, data: data)
            return data
        } catch let error as AIError {
            throw error
        } catch {
            print("[HTTPClient] authorized GET error: \(error)")
            throw AIError.network(error)
        }
    }

    func getJSON<T: Decodable>(_ type: T.Type, url: URL) async throws -> T {
        let request = authorizedRequest(url: url, method: "GET", body: nil, contentType: nil)
        do {
            let (data, response) = try await session.dataWithResponse(request)
            try validate(response: response, data: data)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("[HTTPClient] decode error: \(error), body: \(String(data: data, encoding: .utf8) ?? "")")
                throw AIError.decodingFailed(error.localizedDescription)
            }
        } catch let error as AIError {
            throw error
        } catch {
            print("[HTTPClient] GET error: \(error)")
            throw AIError.network(error)
        }
    }

    /// POST JSON body; returns raw response data (for WaveSpeed responses that don’t match one Codable shape).
    func postJSONData(url: URL, body: Encodable) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let payload = try encoder.encode(AnyEncodable(body))
        let request = authorizedRequest(url: url, method: "POST", body: payload)
        do {
            let (respData, response) = try await session.dataWithResponse(request)
            try validate(response: response, data: respData)
            return respData
        } catch let error as AIError {
            throw error
        } catch {
            print("[HTTPClient] POST error: \(error)")
            throw AIError.network(error)
        }
    }

    func postJSON<T: Decodable>(_ type: T.Type, url: URL, body: Encodable) async throws -> T {
        let respData = try await postJSONData(url: url, body: body)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(T.self, from: respData)
        } catch {
            print("[HTTPClient] POST decode error: \(error), body: \(String(data: respData, encoding: .utf8) ?? "")")
            throw AIError.decodingFailed(error.localizedDescription)
        }
    }

    func uploadMultipart(url: URL, fieldName: String, filename: String, mimeType: String, data: Data, boundary: String) async throws -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 180

        do {
            let (respData, response) = try await session.dataWithResponse(request)
            try validate(response: response, data: respData)
            return respData
        } catch let error as AIError {
            throw error
        } catch {
            print("[HTTPClient] multipart error: \(error)")
            throw AIError.network(error)
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AIError.invalidResponse(statusCode: -1, body: nil)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw AIError.invalidResponse(statusCode: http.statusCode, body: body)
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        encodeFunc = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}

private extension URLSession {
    func dataWithResponse(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIError.invalidResponse(statusCode: -1, body: nil)
        }
        return (data, http)
    }
}
