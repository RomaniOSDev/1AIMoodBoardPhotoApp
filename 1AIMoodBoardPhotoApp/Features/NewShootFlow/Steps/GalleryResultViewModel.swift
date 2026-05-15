//
//  GalleryResultViewModel.swift
//  1AIMoodBoardPhotoApp
//

import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
final class GalleryResultViewModel: ObservableObject {
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var didPersistToSwiftData = false

    func saveSessionIfNeeded(
        localURL: URL,
        repository: ShootRepository,
        shootTitle: String?
    ) async {
        do {
            if !didPersistToSwiftData {
                _ = try repository.saveGeneration(localFileURL: localURL, shootTitle: shootTitle)
                didPersistToSwiftData = true
                print("[GalleryResult] saved SwiftData")
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("[GalleryResult] save session error: \(error)")
        }
    }

    func saveToPhotoLibrary(image: UIImage?) async -> Bool {
        do {
            guard let image else {
                throw NSError(domain: "Gallery", code: 1, userInfo: [NSLocalizedDescriptionKey: L10n.Gallery.missingImageError])
            }
            let saver = PhotoAlbumSaver()
            try await saver.saveToPhotoLibrary(image)
            print("[GalleryResult] saved photo library")
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("[GalleryResult] save library error: \(error)")
            return false
        }
    }
}
