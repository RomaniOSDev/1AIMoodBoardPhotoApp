//
//  WaveSpeedSubmitParsing.swift
//  1AIMoodBoardPhotoApp
//

import Foundation

enum WaveSpeedSubmitParsing {
    /// WaveSpeed may return `id`, `task_id`, nested under `data`, etc.
    static func taskID(fromJSONData data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return taskID(fromJSONObject: obj)
    }

    static func taskID(fromJSONObject json: [String: Any]) -> String? {
        let keys = ["id", "task_id", "taskId", "request_id", "prediction_id"]

        if let id = pickID(from: json, keys: keys) { return id }
        if let data = json["data"] as? [String: Any], let id = pickID(from: data, keys: keys) { return id }
        if let result = json["result"] as? [String: Any], let id = pickID(from: result, keys: keys) { return id }

        return nil
    }

    private static func pickID(from dict: [String: Any], keys: [String]) -> String? {
        for k in keys {
            if let s = stringFrom(dict[k]), !s.isEmpty { return s }
        }
        return nil
    }

    private static func stringFrom(_ value: Any?) -> String? {
        switch value {
        case let s as String:
            return s
        case let i as Int:
            return String(i)
        case let i as Int64:
            return String(i)
        case let d as Double:
            // JSON sometimes decodes integers as Double
            if d.rounded() == d, d >= 0, d < Double(Int.max) {
                return String(Int(d))
            }
            return nil
        default:
            return nil
        }
    }

    /// `POST .../edit` returns `data.urls.get` — that is the poll URL (`.../predictions/{id}/result`). `GET .../predictions/{id}` returns 404 on v3.
    static func resultPollURLString(fromJSONData data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        func extract(from dict: [String: Any]) -> String? {
            guard let urls = dict["urls"] as? [String: Any] else { return nil }
            if let get = urls["get"] as? String, !get.isEmpty { return get }
            return nil
        }
        if let inner = obj["data"] as? [String: Any], let s = extract(from: inner) { return s }
        return extract(from: obj)
    }
}

// MARK: - Poll (`GET .../predictions/{id}/result`)

enum WaveSpeedPollParsing {
    struct Snapshot: Sendable {
        let status: String
        let outputs: [String]
        let errorMessage: String?
    }

    /// Handles wrapped `{ code, data: { status, outputs } }` and flat shapes.
    static func pollSnapshot(fromJSONData data: Data) -> Snapshot? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let inner = (json["data"] as? [String: Any]) ?? json

        let status = (inner["status"] as? String)
            ?? (json["status"] as? String)
            ?? ""

        var outputs: [String] = []
        if let arr = inner["outputs"] as? [String] {
            outputs = arr
        } else if let arr = json["outputs"] as? [String] {
            outputs = arr
        }

        let errRaw = inner["error"] as? String
        let msg = (errRaw?.isEmpty == false ? errRaw : nil)
            ?? ((inner["message"] as? String).flatMap { $0.isEmpty ? nil : $0 })

        return Snapshot(status: status, outputs: outputs, errorMessage: msg)
    }
}
