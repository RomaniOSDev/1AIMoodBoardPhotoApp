//
//  Endpoints.swift
//  1AIMoodBoardPhotoApp
//

import Foundation

enum Endpoints {
    static let baseURL = URL(string: "https://api.wavespeed.ai/api/v3")!

    /// Legacy single-request upload (bytes via API gateway) — often stalls on some networks.
    static var uploadBinary: URL { baseURL.appendingPathComponent("media/upload/binary") }
    /// Recommended: create upload ticket, then PUT bytes to signed URL (bypasses gateway).
    static var mediaUploads: URL { baseURL.appendingPathComponent("media/uploads") }
    static func imageEdit() -> URL { baseURL.appendingPathComponent("google/nano-banana/edit") }

    /// Poll until outputs appear (same URL as submit response `data.urls.get`).
    static func predictionResult(taskID: String) -> URL {
        baseURL.appendingPathComponent("predictions/\(taskID)/result")
    }
}
