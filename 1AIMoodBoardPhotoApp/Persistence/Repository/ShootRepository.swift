//
//  ShootRepository.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import SwiftData

@MainActor
final class ShootRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchSessionsSorted() throws -> [ShootSession] {
        let descriptor = FetchDescriptor<ShootSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAllPhotosSorted() throws -> [GeneratedPhoto] {
        let descriptor = FetchDescriptor<GeneratedPhoto>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func saveGeneration(localFileURL: URL, shootTitle: String? = nil) throws -> ShootSession {
        let rel = relativePath(from: localFileURL)
        let session = ShootSession(shootTitle: shootTitle)
        let photo = GeneratedPhoto(localRelativePath: rel, session: session)
        session.photos.append(photo)
        modelContext.insert(session)
        modelContext.insert(photo)
        try modelContext.save()
        print("[ShootRepository] saved session=\(session.id) path=\(rel)")
        return session
    }

    func absoluteURL(for photo: GeneratedPhoto) -> URL {
        documentsDirectory().appendingPathComponent(photo.localRelativePath)
    }

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func relativePath(from absoluteURL: URL) -> String {
        let docs = documentsDirectory().path
        let path = absoluteURL.path
        if path.hasPrefix(docs) {
            let idx = path.index(path.startIndex, offsetBy: docs.count)
            let rest = String(path[idx...]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return rest.isEmpty ? absoluteURL.lastPathComponent : rest
        }
        return absoluteURL.lastPathComponent
    }
}
