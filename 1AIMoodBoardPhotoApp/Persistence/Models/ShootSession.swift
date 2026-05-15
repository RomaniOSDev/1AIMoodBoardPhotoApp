//
//  ShootSession.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import SwiftData

@Model
final class ShootSession {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    /// Optional title from “Name this shoot” on step 2.
    var shootTitle: String?
    @Relationship(deleteRule: .cascade, inverse: \GeneratedPhoto.session)
    var photos: [GeneratedPhoto]

    init(id: UUID = UUID(), createdAt: Date = .now, shootTitle: String? = nil, photos: [GeneratedPhoto] = []) {
        self.id = id
        self.createdAt = createdAt
        self.shootTitle = shootTitle
        self.photos = photos
    }

    var generatedCount: Int { photos.count }

    /// Newest generated image in this session (same as thumbnail source).
    var newestPhoto: GeneratedPhoto? {
        photos.max(by: { $0.createdAt < $1.createdAt })
    }

    var thumbnailRelativePath: String? {
        newestPhoto?.localRelativePath
    }
}
