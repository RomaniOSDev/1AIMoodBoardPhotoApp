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

    var thumbnailRelativePath: String? {
        photos.sorted { $0.createdAt > $1.createdAt }.first?.localRelativePath
    }
}
