//
//  MyPhotosViewModel.swift
//  1AIMoodBoardPhotoApp
//

import Combine
import Foundation
import SwiftData

@MainActor
final class MyPhotosViewModel: ObservableObject {
    @Published private(set) var photos: [GeneratedPhoto] = []
    @Published var showError = false
    @Published var errorMessage = ""

    private var repository: ShootRepository?

    func bindRepository(_ repository: ShootRepository) {
        self.repository = repository
    }

    func load() {
        guard let repository else { return }
        do {
            photos = try repository.fetchAllPhotosSorted()
            print("[MyPhotosViewModel] count=\(photos.count)")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("[MyPhotosViewModel] load error: \(error)")
        }
    }

    func absoluteURL(for photo: GeneratedPhoto, repository: ShootRepository) -> URL {
        repository.absoluteURL(for: photo)
    }
}
