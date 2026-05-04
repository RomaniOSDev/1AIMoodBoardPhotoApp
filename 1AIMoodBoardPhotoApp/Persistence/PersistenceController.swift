//
//  PersistenceController.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import SwiftData

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    init(inMemory: Bool = false) {
        let schema = Schema([ShootSession.self, GeneratedPhoto.self])
        do {
            let configuration: ModelConfiguration
            if inMemory {
                configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            } else {
                let storeURL = try Self.prepareStoreURL()
                configuration = ModelConfiguration(url: storeURL)
            }
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("SwiftData container error: \(error)")
        }
    }

    private static func prepareStoreURL() throws -> URL {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        return appSupportURL.appendingPathComponent("default.store", isDirectory: false)
    }
}
