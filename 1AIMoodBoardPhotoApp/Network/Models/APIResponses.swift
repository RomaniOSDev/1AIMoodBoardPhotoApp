//
//  APIResponses.swift
//  1AIMoodBoardPhotoApp
//

import Foundation

// MARK: - Upload ticket (POST /media/uploads) — preferred

struct CreateUploadTicketRequest: Encodable {
    let filename: String
    let size: Int
    let contentType: String?
}

struct CreateUploadTicketResponse: Decodable {
    let code: Int?
    let message: String?
    let data: TicketData

    struct TicketData: Decodable {
        let downloadUrl: String
        let upload: UploadInstructions
    }

    struct UploadInstructions: Decodable {
        let method: String?
        let url: String
        let headers: [String: String]?
        let expiresAt: String?
    }
}

// MARK: - Upload (POST /media/upload/binary) — legacy fallback

/// Matches WaveSpeed docs; live API may use camelCase or alternate keys — see `UploadData`.
struct UploadBinaryResponse: Decodable {
    let code: Int?
    let message: String?
    let data: UploadData

    struct UploadData: Decodable {
        let downloadURL: String

        enum CodingKeys: String, CodingKey {
            case download_url
            case downloadUrl
            case url
            case file_url
            case link
            case file
            case href
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let optionalStrings: [String?] = [
                try c.decodeIfPresent(String.self, forKey: .download_url),
                try c.decodeIfPresent(String.self, forKey: .downloadUrl),
                try c.decodeIfPresent(String.self, forKey: .url),
                try c.decodeIfPresent(String.self, forKey: .file_url),
                try c.decodeIfPresent(String.self, forKey: .link),
                try c.decodeIfPresent(String.self, forKey: .file),
                try c.decodeIfPresent(String.self, forKey: .href)
            ]
            let resolved = optionalStrings.compactMap { $0 }.first { !$0.isEmpty }

            guard let first = resolved else {
                let keys = c.allKeys.map(\.stringValue).joined(separator: ", ")
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "No URL field found in upload data. Keys present: [\(keys)]"
                    )
                )
            }
            downloadURL = first
        }
    }
}

// MARK: - WaveSpeed image edit request
// Task id is parsed in `WaveSpeedSubmitParsing` from raw JSON (several possible shapes).

/// Request body per WaveSpeed image-edit API schema.
struct ImageEditRequestBody: Encodable {
    let enableBase64Output: Bool
    let enableSyncMode: Bool
    let images: [String]
    let outputFormat: String
    let prompt: String
    /// Schema: 1:1, 3:2, …, 9:16, … App prompt asks for 9:16 vertical lifestyle shot.
    let aspectRatio: String?

    static func shootRequest(imageURLs: [String], prompt: String) -> ImageEditRequestBody {
        ImageEditRequestBody(
            // false: poll stays small (CDN URL). Large base64 via api.wavespeed.ai also stalls from RU.
            // Image bytes are fetched afterward: direct CDN, then public image proxies if CDN is geo-blocked.
            enableBase64Output: false,
            enableSyncMode: false,
            images: imageURLs,
            outputFormat: "jpeg",
            prompt: prompt,
            aspectRatio: "9:16"
        )
    }
}

