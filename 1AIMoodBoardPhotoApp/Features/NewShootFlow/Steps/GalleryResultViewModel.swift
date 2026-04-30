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

    func saveToMyPhotosAndLibrary(
        localURL: URL,
        repository: ShootRepository,
        image: UIImage?,
        shootTitle: String?
    ) async {
        do {
            if !didPersistToSwiftData {
                _ = try repository.saveGeneration(localFileURL: localURL, shootTitle: shootTitle)
                didPersistToSwiftData = true
                print("[GalleryResult] saved SwiftData")
            }
            guard let image else {
                throw NSError(domain: "Gallery", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing image"])
            }
            let saver = PhotoAlbumSaver()
            try await saver.saveToPhotoLibrary(image)
            print("[GalleryResult] saved photo library")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("[GalleryResult] save error: \(error)")
        }
    }
}
