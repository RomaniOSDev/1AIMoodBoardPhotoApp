//
//  HTTPClient.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import Network

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
        case .invalidAPIKey: return L10n.Ai.missingAPIKey
        case .invalidURL: return L10n.Ai.invalidURL
        case .invalidResponse(let code, let body):
            return String(format: L10n.Ai.httpFormat, locale: .current, code, body ?? "")
        case .decodingFailed(let detail):
            return String(format: L10n.Ai.decodingFailedFormat, locale: .current, detail)
        case .network(let error): return error.localizedDescription
        case .missingDownloadURL: return L10n.Ai.missingDownload
        case .missingTaskID: return L10n.Ai.noTaskID
        case .predictionFailed(let s): return s.isEmpty ? L10n.Ai.generationRejected : s
        case .timeout: return L10n.Ai.timeout
        case .emptyOutputs: return L10n.Ai.noOutput
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

    /// Public CDN URLs (no `Authorization`). Tries direct host, then image proxies (CloudFront often blocked from RU).
    func getPublicBinary(url: URL) async throws -> Data {
        let candidates = Self.downloadURLCandidates(for: url)
        print("[HTTPClient][DOWNLOAD] source=\(url.absoluteString) candidates=\(candidates.count) timeout=\(Constants.outputDownloadRequestTimeoutSeconds)s")

        var lastError: Error = URLError(.timedOut)
        for (index, candidate) in candidates.enumerated() {
            try Task.checkCancellation()
            let maxAttempts = Constants.outputDownloadMaxAttempts
            for attempt in 1 ... maxAttempts {
                let attemptStarted = Date()
                print("[HTTPClient][DOWNLOAD] [\(candidate.name)] \(index + 1)/\(candidates.count) attempt \(attempt)/\(maxAttempts) host=\(candidate.url.host ?? "?")")
                do {
                    let data = try await getPublicBinarySingleAttempt(url: candidate.url)
                    guard Self.looksLikeImage(data) else {
                        print("[HTTPClient][DOWNLOAD] [\(candidate.name)] not an image bytes=\(data.count) — next")
                        lastError = AIError.decodingFailed("Proxy returned non-image")
                        break
                    }
                    print("[HTTPClient][DOWNLOAD] [\(candidate.name)] OK bytes=\(data.count) in \(String(format: "%.2f", Date().timeIntervalSince(attemptStarted)))s")
                    return data
                } catch let error as URLError where error.code == .cancelled {
                    throw error
                } catch let error as AIError {
                    lastError = error
                    print("[HTTPClient][DOWNLOAD] [\(candidate.name)] AIError: \(error)")
                    break
                } catch let error as URLError where Self.isTransientNetworkError(error) && attempt < maxAttempts {
                    lastError = error
                    print("[HTTPClient][DOWNLOAD] [\(candidate.name)] transient \(error.code.rawValue) — retry")
                    try await Task.sleep(nanoseconds: 500_000_000)
                } catch {
                    lastError = error
                    let ns = error as NSError
                    print("[HTTPClient][DOWNLOAD] [\(candidate.name)] FAILED domain=\(ns.domain) code=\(ns.code) — next candidate")
                    break
                }
            }
        }
        if let urlError = lastError as? URLError {
            throw AIError.network(urlError)
        }
        if let ai = lastError as? AIError {
            throw ai
        }
        throw AIError.network(lastError)
    }

    private struct DownloadCandidate: Sendable {
        let name: String
        let url: URL
    }

    /// Direct CDN first, then public fetch proxies that pull CloudFront from outside RU.
    private static func downloadURLCandidates(for source: URL) -> [DownloadCandidate] {
        var list: [DownloadCandidate] = [.init(name: "direct", url: source)]

        func proxyURL(base: String, queryName: String, extra: [URLQueryItem] = []) -> URL? {
            var components = URLComponents(string: base)
            var items = [URLQueryItem(name: queryName, value: source.absoluteString)]
            items.append(contentsOf: extra)
            components?.queryItems = items
            return components?.url
        }

        if let wsrv = proxyURL(base: "https://wsrv.nl/", queryName: "url", extra: [.init(name: "output", value: "jpg")]) {
            list.append(.init(name: "wsrv", url: wsrv))
        }
        if let weserv = proxyURL(base: "https://images.weserv.nl/", queryName: "url", extra: [.init(name: "output", value: "jpg")]) {
            list.append(.init(name: "weserv", url: weserv))
        }
        if let ddg = proxyURL(base: "https://proxy.duckduckgo.com/iu/", queryName: "u") {
            list.append(.init(name: "ddg", url: ddg))
        }
        return list
    }

    private static func looksLikeImage(_ data: Data) -> Bool {
        guard data.count >= 3 else { return false }
        let b = [UInt8](data.prefix(12))
        let jpeg = b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF
        let png = b.count >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47
        let webp = b.count >= 12 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46
        let gif = b.count >= 6 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46
        return jpeg || png || webp || gif
    }

    private static func isTransientNetworkError(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut, .networkConnectionLost, .cannotConnectToHost, .notConnectedToInternet, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private func getPublicBinarySingleAttempt(url: URL) async throws -> Data {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = Constants.outputDownloadRequestTimeoutSeconds
        config.timeoutIntervalForResource = Constants.outputDownloadResourceTimeoutSeconds
        config.waitsForConnectivity = false
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        let downloadSession = URLSession(configuration: config)
        defer { downloadSession.finishTasksAndInvalidate() }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Constants.outputDownloadRequestTimeoutSeconds
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let started = Date()
        let heartbeat = Task {
            var tick = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { return }
                tick += 1
                print("[HTTPClient][DOWNLOAD] …still waiting \(String(format: "%.0f", Date().timeIntervalSince(started)))s (tick=\(tick)) host=\(url.host ?? "?")")
            }
        }
        defer { heartbeat.cancel() }

        do {
            let (data, response) = try await downloadSession.data(for: request)
            heartbeat.cancel()
            guard let http = response as? HTTPURLResponse else {
                throw AIError.invalidResponse(statusCode: -1, body: nil)
            }
            print("[HTTPClient][DOWNLOAD] response status=\(http.statusCode) bytes=\(data.count) in \(String(format: "%.2f", Date().timeIntervalSince(started)))s")
            guard (200 ... 299).contains(http.statusCode) else {
                let body = String(data: data.prefix(800), encoding: .utf8)
                throw AIError.invalidResponse(statusCode: http.statusCode, body: body)
            }
            return data
        } catch let error as AIError {
            heartbeat.cancel()
            throw error
        } catch {
            heartbeat.cancel()
            throw error
        }
    }

    /// Authenticated GET returning raw JSON/data (e.g. `/predictions/{id}/result`).
    func getAuthorizedData(url: URL) async throws -> Data {
        let started = Date()
        print("[HTTPClient][POLL] GET \(url.absoluteString)")

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = Constants.pollRequestTimeoutSeconds
        config.timeoutIntervalForResource = Constants.pollRequestTimeoutSeconds
        config.waitsForConnectivity = false
        let pollSession = URLSession(configuration: config)
        defer { pollSession.finishTasksAndInvalidate() }

        var request = authorizedRequest(url: url, method: "GET", body: nil, contentType: nil)
        request.timeoutInterval = Constants.pollRequestTimeoutSeconds

        let heartbeat = Task {
            var tick = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                tick += 1
                print("[HTTPClient][POLL] …still waiting \(String(format: "%.0f", Date().timeIntervalSince(started)))s (tick=\(tick))")
            }
        }
        defer { heartbeat.cancel() }

        do {
            let (data, response) = try await pollSession.data(for: request)
            heartbeat.cancel()
            guard let http = response as? HTTPURLResponse else {
                throw AIError.invalidResponse(statusCode: -1, body: nil)
            }
            print("[HTTPClient][POLL] status=\(http.statusCode) bytes=\(data.count) in \(String(format: "%.2f", Date().timeIntervalSince(started)))s")
            try validate(response: response, data: data)
            return data
        } catch let error as AIError {
            heartbeat.cancel()
            print("[HTTPClient][POLL] AIError after \(String(format: "%.2f", Date().timeIntervalSince(started)))s: \(error)")
            throw error
        } catch {
            heartbeat.cancel()
            let ns = error as NSError
            print("[HTTPClient][POLL] FAILED after \(String(format: "%.2f", Date().timeIntervalSince(started)))s domain=\(ns.domain) code=\(ns.code) \(error.localizedDescription)")
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
        let maxAttempts = 3
        print("[HTTPClient][SUBMIT] POST \(url.absoluteString) payloadBytes=\(payload.count) maxAttempts=\(maxAttempts)")

        for attempt in 1 ... maxAttempts {
            let started = Date()
            // Fresh ephemeral session each attempt — avoids stale QUIC connections (-1005).
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 60
            config.timeoutIntervalForResource = 90
            config.waitsForConnectivity = false
            let submitSession = URLSession(configuration: config)
            defer { submitSession.finishTasksAndInvalidate() }

            var request = authorizedRequest(url: url, method: "POST", body: payload)
            request.timeoutInterval = 60
            print("[HTTPClient][SUBMIT] attempt \(attempt)/\(maxAttempts)")
            do {
                let (respData, response) = try await submitSession.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw AIError.invalidResponse(statusCode: -1, body: nil)
                }
                print("[HTTPClient][SUBMIT] status=\(http.statusCode) bytes=\(respData.count) in \(String(format: "%.2f", Date().timeIntervalSince(started)))s")
                try validate(response: response, data: respData)
                return respData
            } catch let error as AIError {
                print("[HTTPClient][SUBMIT] AIError after \(String(format: "%.2f", Date().timeIntervalSince(started)))s: \(error)")
                throw error
            } catch let error as URLError where Self.isTransientNetworkError(error) && attempt < maxAttempts {
                print("[HTTPClient][SUBMIT] attempt \(attempt) transient \(error.code.rawValue) — retrying…")
                try await Task.sleep(nanoseconds: UInt64(800_000_000 * UInt64(attempt)))
            } catch {
                let ns = error as NSError
                print("[HTTPClient][SUBMIT] FAILED after \(String(format: "%.2f", Date().timeIntervalSince(started)))s domain=\(ns.domain) code=\(ns.code) \(error.localizedDescription)")
                throw AIError.network(error)
            }
        }
        throw AIError.network(URLError(.networkConnectionLost))
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

    /// PUT raw bytes to a signed storage URL. Do **not** send API Authorization.
    func putRawBytes(url: URL, data: Data, headers: [String: String]) async throws {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = Constants.uploadRequestTimeoutSeconds
        config.timeoutIntervalForResource = Constants.uploadResourceTimeoutSeconds
        config.waitsForConnectivity = false
        let putSession = URLSession(configuration: config)
        defer { putSession.finishTasksAndInvalidate() }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = Constants.uploadRequestTimeoutSeconds
        for (key, value) in headers {
            // Never attach WaveSpeed Bearer to the signed PUT.
            if key.lowercased() == "authorization" { continue }
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")

        let host = url.host ?? "?"
        let started = Date()
        print("[HTTPClient][PUT] host=\(host) bytes=\(data.count) headerKeys=\(headers.keys.sorted())")

        let heartbeat = Task {
            var tick = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                tick += 1
                print("[HTTPClient][PUT] …still waiting \(String(format: "%.0f", Date().timeIntervalSince(started)))s (tick=\(tick))")
            }
        }
        defer { heartbeat.cancel() }

        do {
            let (respData, response) = try await putSession.upload(for: request, from: data)
            heartbeat.cancel()
            guard let http = response as? HTTPURLResponse else {
                throw AIError.invalidResponse(statusCode: -1, body: nil)
            }
            print("[HTTPClient][PUT] status=\(http.statusCode) respBytes=\(respData.count) in \(String(format: "%.2f", Date().timeIntervalSince(started)))s")
            guard (200 ... 299).contains(http.statusCode) else {
                let body = String(data: respData.prefix(400), encoding: .utf8)
                throw AIError.invalidResponse(statusCode: http.statusCode, body: body)
            }
        } catch let error as AIError {
            throw error
        } catch {
            let ns = error as NSError
            print("[HTTPClient][PUT] FAILED after \(String(format: "%.2f", Date().timeIntervalSince(started)))s domain=\(ns.domain) code=\(ns.code) \(error.localizedDescription)")
            throw error
        }
    }

    func uploadMultipart(url: URL, fieldName: String, filename: String, mimeType: String, data: Data, boundary: String) async throws -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        print("[HTTPClient][UPLOAD] url=\(url.absoluteString) fileBytes=\(data.count) bodyBytes=\(body.count) maxAttempts=\(Constants.uploadMaxAttempts) requestTimeout=\(Constants.uploadRequestTimeoutSeconds)s resourceTimeout=\(Constants.uploadResourceTimeoutSeconds)s keyPrefix=\(apiKey.prefix(12))…")
        await logNetworkPath(tag: "UPLOAD")

        let maxAttempts = Constants.uploadMaxAttempts
        for attempt in 1 ... maxAttempts {
            let attemptStarted = Date()
            print("[HTTPClient][UPLOAD] attempt \(attempt)/\(maxAttempts) START \(attemptStarted)")
            do {
                let result = try await uploadMultipartSingleAttempt(
                    url: url,
                    body: body,
                    boundary: boundary
                )
                print("[HTTPClient][UPLOAD] attempt \(attempt) OK in \(String(format: "%.2f", Date().timeIntervalSince(attemptStarted)))s respBytes=\(result.count)")
                return result
            } catch let error as AIError {
                print("[HTTPClient][UPLOAD] attempt \(attempt) AIError after \(String(format: "%.2f", Date().timeIntervalSince(attemptStarted)))s: \(error)")
                throw error
            } catch let error as URLError where error.code == .timedOut && attempt < maxAttempts {
                print("[HTTPClient][UPLOAD] attempt \(attempt) TIMED OUT after \(String(format: "%.2f", Date().timeIntervalSince(attemptStarted)))s code=\(error.code.rawValue) — retrying…")
                try await Task.sleep(nanoseconds: UInt64(1_500_000_000 * UInt64(attempt)))
            } catch {
                let ns = error as NSError
                print("[HTTPClient][UPLOAD] attempt \(attempt) FAILED after \(String(format: "%.2f", Date().timeIntervalSince(attemptStarted)))s domain=\(ns.domain) code=\(ns.code) desc=\(error.localizedDescription)")
                throw AIError.network(error)
            }
        }
        print("[HTTPClient][UPLOAD] all \(maxAttempts) attempts exhausted → timeout")
        throw AIError.network(URLError(.timedOut))
    }

    private func uploadMultipartSingleAttempt(url: URL, body: Data, boundary: String) async throws -> Data {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = Constants.uploadRequestTimeoutSeconds
        config.timeoutIntervalForResource = Constants.uploadResourceTimeoutSeconds
        // false: with true, URLSession can sit forever waiting for "connectivity"
        // and request timeout does not start until then — looks like a hang after "sending POST".
        config.waitsForConnectivity = false
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        let uploadSession = URLSession(configuration: config)
        defer { uploadSession.finishTasksAndInvalidate() }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        request.timeoutInterval = Constants.uploadRequestTimeoutSeconds

        let started = Date()
        print("[HTTPClient][UPLOAD] sending upload(for:from:) bodyBytes=\(body.count) waitsForConnectivity=false")

        // Heartbeat so Console shows the request is still blocked on the wire.
        let heartbeat = Task {
            var tick = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                tick += 1
                let elapsed = Date().timeIntervalSince(started)
                print("[HTTPClient][UPLOAD] …still waiting \(String(format: "%.0f", elapsed))s (tick=\(tick)) — no response yet")
            }
        }
        defer { heartbeat.cancel() }

        do {
            // Prefer upload task (streams body) over data(for:) + httpBody.
            let (respData, response) = try await uploadSession.upload(for: request, from: body)
            heartbeat.cancel()
            if let http = response as? HTTPURLResponse {
                print("[HTTPClient][UPLOAD] response status=\(http.statusCode) bytes=\(respData.count) in \(String(format: "%.2f", Date().timeIntervalSince(started)))s bodyPrefix=\(String(data: respData.prefix(200), encoding: .utf8) ?? "<bin>")")
            } else {
                print("[HTTPClient][UPLOAD] response is not HTTPURLResponse after \(String(format: "%.2f", Date().timeIntervalSince(started)))s")
            }
            try validate(response: response, data: respData)
            return respData
        } catch {
            heartbeat.cancel()
            let ns = error as NSError
            print("[HTTPClient][UPLOAD] transport error after \(String(format: "%.2f", Date().timeIntervalSince(started)))s domain=\(ns.domain) code=\(ns.code) desc=\(error.localizedDescription)")
            throw error
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

    /// Snapshot of current NWPath so we can tell "no route" from "server silent".
    private func logNetworkPath(tag: String) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            final class Once: @unchecked Sendable {
                private var done = false
                private let lock = NSLock()
                func run(_ body: () -> Void) {
                    lock.lock()
                    defer { lock.unlock() }
                    guard !done else { return }
                    done = true
                    body()
                }
            }
            let once = Once()
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "HTTPClient.NWPath.\(tag)")
            monitor.pathUpdateHandler = { path in
                once.run {
                    let interfaces = path.availableInterfaces.map { "\($0.type)" }.joined(separator: ",")
                    print("[HTTPClient][\(tag)] NWPath status=\(path.status) expensive=\(path.isExpensive) constrained=\(path.isConstrained) interfaces=[\(interfaces)]")
                    monitor.cancel()
                    cont.resume()
                }
            }
            monitor.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 1.5) {
                once.run {
                    print("[HTTPClient][\(tag)] NWPath timeout — no path update")
                    monitor.cancel()
                    cont.resume()
                }
            }
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
