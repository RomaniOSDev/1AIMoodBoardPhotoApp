//
//  AIService.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import UIKit

actor AIService {
    enum Mode: String, Sendable {
        case mock
        case live
    }

    private var mode: Mode
    private let http: HTTPClient
    private let fileManager: FileManager

    init(
        mode: Mode = .mock,
        apiKey: String = Constants.wavespeedAPIKey,
        fileManager: FileManager = .default
    ) {
        self.mode = mode
        self.http = HTTPClient(apiKey: apiKey)
        self.fileManager = fileManager
    }

    func setMode(_ newMode: Mode) {
        mode = newMode
    }

    // MARK: - Public API

    nonisolated static func buildPrompt(stylePreset: VibePreset?, customPrompt: String?) -> String {
        let base =
            "The first image is one person in everyday clothing. Generate a NEW vertical lifestyle photograph (9:16) of the same individual; keep face and overall likeness consistent; fully clothed, modest styling."
        let style = stylePreset.map { "Style direction: \($0.promptFragment)" } ?? "Style direction: modern, clean lifestyle portrait."
        let trimmedCustom = (customPrompt ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let custom = trimmedCustom.isEmpty ? "" : "Custom edit request: \(trimmedCustom)"
        return [base, style, custom, "Clean composition, relaxed pose, crisp detail. No text, logos, or watermarks."]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    func uploadImage(data: Data, filename: String = "image.jpg") async throws -> String {
        try validateAPIKeyForLive()
        print("[AIService] uploadImage start bytes=\(data.count) mode=\(mode)")

        switch mode {
        case .mock:
            return "https://mock.local/\(filename)"
        case .live:
            let boundary = "Boundary-\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
            let responseData = try await http.uploadMultipart(
                url: Endpoints.uploadBinary,
                fieldName: "file",
                filename: filename,
                mimeType: "image/jpeg",
                data: data,
                boundary: boundary
            )
            let decoder = JSONDecoder()
            let decoded: UploadBinaryResponse
            do {
                decoded = try decoder.decode(UploadBinaryResponse.self, from: responseData)
            } catch {
                print("[AIService] upload decode failed: \(error). Raw: \(String(data: responseData.prefix(2000), encoding: .utf8) ?? "")")
                throw error
            }
            if let code = decoded.code, code != 200 {
                print("[AIService] upload non-200 body code=\(code) message=\(decoded.message ?? "")")
                throw AIError.invalidResponse(statusCode: code, body: decoded.message)
            }
            guard let url = Optional(decoded.data.downloadURL), !url.isEmpty else {
                throw AIError.missingDownloadURL
            }
            print("[AIService] upload ok url=\(url.prefix(80))...")
            return url
        }
    }

    struct SubmitEditOutcome: Sendable {
        let taskID: String
        /// Live only: from `data.urls.get`, or `Endpoints.predictionResult(taskID)`.
        let resultPollURL: URL?
    }

    struct GenerationProgress: Sendable {
        let value: Double
        let label: String
    }

    func submitEdit(imageURLs: [String], prompt: String) async throws -> SubmitEditOutcome {
        try validateAPIKeyForLive()
        print("[AIService] submitEdit images=\(imageURLs.count)")

        switch mode {
        case .mock:
            return SubmitEditOutcome(taskID: UUID().uuidString, resultPollURL: nil)
        case .live:
            let body = NanoBananaEditBody.shootRequest(imageURLs: imageURLs, prompt: prompt)
            let respData = try await http.postJSONData(url: Endpoints.nanoBananaEdit(), body: body)
            let rawSnippet = String(data: respData.prefix(1500), encoding: .utf8) ?? ""
            print("[AIService] submitEdit raw: \(rawSnippet)")

            guard let taskID = WaveSpeedSubmitParsing.taskID(fromJSONData: respData), !taskID.isEmpty else {
                print("[AIService] submitEdit could not parse task id from JSON")
                throw AIError.missingTaskID
            }
            let pollString = WaveSpeedSubmitParsing.resultPollURLString(fromJSONData: respData)
            let pollURL = pollString.flatMap { URL(string: $0) } ?? Endpoints.predictionResult(taskID: taskID)
            print("[AIService] submitEdit taskID=\(taskID) pollURL=\(pollURL.absoluteString)")
            return SubmitEditOutcome(taskID: taskID, resultPollURL: pollURL)
        }
    }

    func pollForResult(
        taskID: String,
        resultPollURL: URL?,
        onProgress: (@Sendable (GenerationProgress) -> Void)? = nil
    ) async throws -> String {
        try validateAPIKeyForLive()
        print("[AIService] pollForResult taskID=\(taskID)")

        switch mode {
        case .mock:
            return "https://mock.local/result.png"
        case .live:
            guard let pollURL = resultPollURL else {
                throw AIError.mockFailure("Missing result poll URL.")
            }
            for attempt in 1 ... Constants.maxPollAttempts {
                let data = try await http.getAuthorizedData(url: pollURL)

                if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let code = obj["code"] as? Int, code != 200 {
                    let msg = (obj["message"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "code \(code)"
                    throw AIError.predictionFailed(msg)
                }

                guard let snapshot = WaveSpeedPollParsing.pollSnapshot(fromJSONData: data) else {
                    print("[AIService] poll parse failed body=\(String(data: data.prefix(800), encoding: .utf8) ?? "")")
                    throw AIError.decodingFailed("poll response")
                }
                print("[AIService] poll attempt=\(attempt) status=\(snapshot.status) outputs=\(snapshot.outputs.count)")
                // Non-linear progress: reaches ~80% around 10-12 attempts (typical), then slows down.
                let eased = 1.0 - exp(-Double(attempt) / 4.0)
                let pollProgress = 0.30 + eased * 0.58
                onProgress?(GenerationProgress(value: min(max(pollProgress, 0), 0.90), label: "Generating"))

                if let output = firstOutput(from: snapshot.outputs) {
                    onProgress?(GenerationProgress(value: 0.90, label: "Finalizing"))
                    return output
                }

                switch snapshot.status.lowercased() {
                case "completed", "succeeded", "success":
                    try await Task.sleep(nanoseconds: Constants.pollIntervalSeconds * 1_000_000_000)
                case "failed", "error", "canceled", "cancelled":
                    let detail = snapshot.errorMessage ?? snapshot.status
                    throw AIError.predictionFailed(detail)
                default:
                    try await Task.sleep(nanoseconds: Constants.pollIntervalSeconds * 1_000_000_000)
                }
            }
            throw AIError.timeout
        }
    }

    private func firstOutput(from outputs: [String]) -> String? {
        for raw in outputs {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            return trimmed
        }
        return nil
    }

    func downloadImage(from output: String) async throws -> Data {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("data:image"), let data = decodeDataURI(trimmed) {
            print("[AIService] downloadImage data URI bytes=\(data.count)")
            return data
        }
        // enable_base64_output: true → naked base64, no data: prefix (WaveSpeed docs).
        if let data = decodeNakedBase64ImageOutput(trimmed) {
            print("[AIService] downloadImage naked base64 bytes=\(data.count)")
            return data
        }
        guard let remoteURL = URL(string: trimmed) else {
            throw AIError.decodingFailed("Invalid output URL/data URI")
        }
        print("[AIService] downloadImage url=\(remoteURL.absoluteString.prefix(60))...")
        switch mode {
        case .mock:
            return try mockPNGData()
        case .live:
            if remoteURL.scheme == "https", remoteURL.host == "mock.local" {
                return try mockPNGData()
            }
            let data = try await http.getPublicBinary(url: remoteURL)
            print("[AIService] downloadImage ok bytes=\(data.count)")
            return data
        }
    }

    /// One selfie + optional style preset + optional custom prompt text.
    func generateShoot(
        selfieImages: [UIImage],
        stylePreset: VibePreset?,
        customPrompt: String?,
        onProgress: (@Sendable (GenerationProgress) -> Void)? = nil
    ) async throws -> URL {
        guard selfieImages.count == 1 else {
            throw AIError.mockFailure("Add exactly one photo of yourself.")
        }
        let trimmedPrompt = customPrompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard stylePreset != nil || !trimmedPrompt.isEmpty else {
            throw AIError.mockFailure("Select a style preset or enter a custom prompt.")
        }

        let styleName = stylePreset?.rawValue ?? "none"
        print("[AIService] generateShoot mode=\(mode) style=\(styleName) customPrompt=\(!trimmedPrompt.isEmpty)")
        onProgress?(GenerationProgress(value: 0.06, label: "Preparing"))

        let prompt = Self.buildPrompt(stylePreset: stylePreset, customPrompt: trimmedPrompt)
        let selfieData = try preparedJPEGData(from: selfieImages[0])
        let uploadItems: [(String, Data)] = [("selfie", selfieData)]
        let uploadedURLs = try await uploadAllParallel(items: uploadItems)
        onProgress?(GenerationProgress(value: 0.22, label: "Uploaded"))

        let submitOutcome = try await submitEdit(imageURLs: uploadedURLs, prompt: prompt)
        onProgress?(GenerationProgress(value: 0.30, label: "Queued"))
        let output = try await pollForResult(taskID: submitOutcome.taskID, resultPollURL: submitOutcome.resultPollURL, onProgress: onProgress)
        onProgress?(GenerationProgress(value: 0.94, label: "Downloading"))
        let imageData = try await downloadImage(from: output)

        let localURL = documentsDirectory().appendingPathComponent("generated_\(UUID().uuidString).png")
        try imageData.write(to: localURL, options: .atomic)
        onProgress?(GenerationProgress(value: 1.0, label: "Done"))
        print("[AIService] generateShoot saved=\(localURL.path)")
        return localURL
    }

    // MARK: - Helpers

    private func validateAPIKeyForLive() throws {
        if mode == .live {
            let key = Constants.wavespeedAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, key != "YOUR_WAVESPEED_API_KEY" else {
                throw AIError.invalidAPIKey
            }
        }
    }

    private func uploadAllParallel(items: [(prefix: String, data: Data)]) async throws -> [String] {
        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (index, item) in items.enumerated() {
                group.addTask {
                    let url = try await self.uploadImage(data: item.data, filename: "\(item.prefix)_\(index).jpg")
                    return (index, url)
                }
            }
            var results: [(Int, String)] = []
            for try await item in group {
                results.append(item)
            }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    private func preparedJPEGData(from image: UIImage) throws -> Data {
        guard let data = image.jpegDataCompressed(quality: Constants.jpegQuality) else {
            throw AIError.mockFailure("Could not compress image.")
        }
        return data
    }

    private func documentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func mockPNGData() throws -> Data {
        let size = CGSize(width: 9, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.systemOrange.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        guard let data = image.pngData() else {
            throw AIError.mockFailure("Mock PNG failed.")
        }
        return data
    }

    private func decodeDataURI(_ value: String) -> Data? {
        guard let comma = value.firstIndex(of: ",") else { return nil }
        let payload = String(value[value.index(after: comma)...])
        return Data(base64Encoded: payload, options: .ignoreUnknownCharacters)
    }

    /// Decodes WaveSpeed `enable_base64_output` strings: standard base64, full string, no MIME wrapper.
    private func decodeNakedBase64ImageOutput(_ value: String) -> Data? {
        let lower = value.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            return nil
        }
        guard value.count >= 32 else { return nil }

        guard let data = Data(base64Encoded: value, options: .ignoreUnknownCharacters) else {
            return nil
        }
        guard data.count >= 12 else { return nil }

        let bytes = [UInt8](data.prefix(8))
        let isPNG = bytes.count >= 8
            && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47
            && bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A
        let isJPEG = bytes.count >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF
        // WebP: RIFF .... WEBP
        let isWebP = data.count >= 12
            && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46
            && data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50

        if isPNG || isJPEG || isWebP {
            return data
        }
        return nil
    }
}
