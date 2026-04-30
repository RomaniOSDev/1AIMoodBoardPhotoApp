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

    nonisolated static func buildPrompt(stylePreset: VibePreset?, hasReferenceImage: Bool) -> String {
        let base =
            "The first image is one person in everyday clothing. Generate a NEW vertical lifestyle photograph (9:16) of the same individual; keep face and overall likeness consistent; fully clothed, modest styling."
        let style = stylePreset.map { "Style direction: \($0.promptFragment)" } ?? "Style direction: modern, clean lifestyle portrait."
        let ref = hasReferenceImage ? "If a second image is provided, use it only as visual style reference (colors, mood, outfit direction), not identity." : ""
        return [base, style, ref, "Clean composition, relaxed pose, crisp detail. No text, logos, or watermarks."]
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

    func pollForResult(taskID: String, resultPollURL: URL?) async throws -> String {
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

                if let output = firstOutput(from: snapshot.outputs) {
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
            print("[AIService] downloadImage inline base64 bytes=\(data.count)")
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

    /// One selfie + optional style preset and optional reference image.
    func generateShoot(selfieImages: [UIImage], stylePreset: VibePreset?, referenceImage: UIImage?) async throws -> URL {
        guard selfieImages.count == 1 else {
            throw AIError.mockFailure("Add exactly one photo of yourself.")
        }
        guard stylePreset != nil || referenceImage != nil else {
            throw AIError.mockFailure("Add a reference photo or select a style preset.")
        }

        let styleName = stylePreset?.rawValue ?? "none"
        let hasRef = referenceImage != nil
        print("[AIService] generateShoot mode=\(mode) style=\(styleName) reference=\(hasRef)")

        let prompt = Self.buildPrompt(stylePreset: stylePreset, hasReferenceImage: hasRef)
        let selfieData = try preparedJPEGData(from: selfieImages[0])
        var uploadItems: [(String, Data)] = [("selfie", selfieData)]
        if let referenceImage {
            uploadItems.append(("reference", try preparedJPEGData(from: referenceImage)))
        }
        let uploadedURLs = try await uploadAllParallel(items: uploadItems)

        let submitOutcome = try await submitEdit(imageURLs: uploadedURLs, prompt: prompt)
        let output = try await pollForResult(taskID: submitOutcome.taskID, resultPollURL: submitOutcome.resultPollURL)
        let imageData = try await downloadImage(from: output)

        let localURL = documentsDirectory().appendingPathComponent("generated_\(UUID().uuidString).png")
        try imageData.write(to: localURL, options: .atomic)
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
}
