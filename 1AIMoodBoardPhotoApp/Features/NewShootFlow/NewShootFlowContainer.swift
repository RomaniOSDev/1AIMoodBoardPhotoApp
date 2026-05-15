//
//  NewShootFlowContainer.swift
//  1AIMoodBoardPhotoApp
//

import SwiftData
import SwiftUI

struct NewShootFlowContainer: View {
    @Environment(\.modelContext) private var modelContext
    let dependencies: AppDependencies
    var onComplete: () -> Void

    @StateObject private var coordinator = NewShootCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            UploadSelfiesView(coordinator: coordinator)
            .navigationDestination(for: NewShootCoordinator.Screen.self) { screen in
                switch screen {
                case .styleSelection:
                    StyleSelectionView(coordinator: coordinator)
                case .processing:
                    ProcessingView(
                        dependencies: dependencies,
                        coordinator: coordinator
                    )
                case .galleryResult:
                    GalleryResultView(
                        dependencies: dependencies,
                        coordinator: coordinator,
                        modelContext: modelContext,
                        onDone: onComplete
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.Shoot.close) {
                    coordinator.resetFlow()
                    onComplete()
                }
            }
        }
    }
}
