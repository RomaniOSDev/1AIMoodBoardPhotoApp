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
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("SwiftData container error: \(error)")
        }
    }
}
