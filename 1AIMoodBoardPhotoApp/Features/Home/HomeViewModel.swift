//
//  HomeViewModel.swift
//  1AIMoodBoardPhotoApp
//

import Combine
import Foundation
import SwiftData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var sessions: [ShootSession] = []
    @Published var showNewShoot = false
    @Published var errorMessage: String?
    @Published var showError = false

    private var repository: ShootRepository?

    func bindRepository(_ repository: ShootRepository) {
        self.repository = repository
    }

    func load() {
        guard let repository else { return }
        do {
            sessions = try repository.fetchSessionsSorted()
            print("[HomeViewModel] loaded sessions=\(sessions.count)")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("[HomeViewModel] load error: \(error)")
        }
    }
}
