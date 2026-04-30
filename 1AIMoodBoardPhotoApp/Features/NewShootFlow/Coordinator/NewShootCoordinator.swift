//
//  NewShootCoordinator.swift
//  1AIMoodBoardPhotoApp
//

import Combine
import SwiftUI
import UIKit

final class NewShootCoordinator: ObservableObject {
    enum Screen: Hashable {
        case processing
        case galleryResult
    }

    @Published var path = NavigationPath()
    @Published var selfieImages: [UIImage] = []
    @Published var selectedVibe: VibePreset?
    /// Typed on step 1 (“Name this shoot”); persisted when saving.
    @Published var shootTitleDraft: String = ""
    @Published var generatedFileURL: URL?

    func push(_ screen: Screen) {
        path.append(screen)
        print("[NewShootCoordinator] push \(screen)")
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func resetFlow() {
        path = NavigationPath()
        selfieImages = []
        selectedVibe = nil
        shootTitleDraft = ""
        generatedFileURL = nil
    }
}
