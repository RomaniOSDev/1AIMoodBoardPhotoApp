//
//  GeneratedPhoto.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import SwiftData

@Model
final class GeneratedPhoto {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    /// Path relative to Documents (filename only or subpath).
    var localRelativePath: String
    var session: ShootSession?

    init(id: UUID = UUID(), createdAt: Date = .now, localRelativePath: String, session: ShootSession? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.localRelativePath = localRelativePath
        self.session = session
    }
}
