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

    func deletePhoto(_ photo: GeneratedPhoto) throws {
        let fileURL = absoluteURL(for: photo)
        let parentSession = photo.session
        let shouldDeleteSession = (parentSession?.photos.count ?? 0) <= 1

        modelContext.delete(photo)
        if shouldDeleteSession, let parentSession {
            modelContext.delete(parentSession)
        }
        try modelContext.save()

        try? FileManager.default.removeItem(at: fileURL)
        print("[ShootRepository] deleted photo=\(photo.id)")
    }

    func resetAllData() throws {
        let photos = try fetchAllPhotosSorted()
        for photo in photos {
            let fileURL = absoluteURL(for: photo)
            try? FileManager.default.removeItem(at: fileURL)
        }

        let sessions = try fetchSessionsSorted()
        for session in sessions {
            modelContext.delete(session)
        }
        try modelContext.save()
        print("[ShootRepository] reset all sessions=\(sessions.count) files=\(photos.count)")
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
