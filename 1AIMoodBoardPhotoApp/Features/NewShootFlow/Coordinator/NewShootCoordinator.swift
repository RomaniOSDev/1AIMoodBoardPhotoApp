//
//  NewShootCoordinator.swift
//  1AIMoodBoardPhotoApp
//

import Combine
import SwiftUI
import UIKit

final class NewShootCoordinator: ObservableObject {
    enum Screen: Hashable {
        case styleSelection
        case processing
        case galleryResult
    }

    @Published var path = NavigationPath()
    @Published var selfieImages: [UIImage] = []
    @Published var selectedVibe: VibePreset?
    @Published var customPrompt: String = ""
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
        customPrompt = ""
        generatedFileURL = nil
    }

    /// Title persisted with the generated photo (localized preset or trimmed custom prompt).
    var resolvedShootTitleForSave: String? {
        if let selectedVibe { return selectedVibe.localizedTitle }
        let trimmed = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if trimmed.count <= 80 { return trimmed }
        return String(trimmed.prefix(80)) + "…"
    }
}
