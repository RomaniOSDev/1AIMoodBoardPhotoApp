//
//  Endpoints.swift
//  1AIMoodBoardPhotoApp
//

import Foundation

enum Endpoints {
    static let baseURL = URL(string: "https://api.wavespeed.ai/api/v3")!

    static var uploadBinary: URL { baseURL.appendingPathComponent("media/upload/binary") }
    static func nanoBananaEdit() -> URL { baseURL.appendingPathComponent("google/nano-banana/edit") }

    /// Poll until outputs appear (same URL as submit response `data.urls.get`).
    static func predictionResult(taskID: String) -> URL {
        baseURL.appendingPathComponent("predictions/\(taskID)/result")
    }
}
