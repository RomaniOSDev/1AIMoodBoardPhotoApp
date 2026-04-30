//
//  GalleryResultView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftData
import SwiftUI

struct GalleryResultView: View {
    let dependencies: AppDependencies
    @ObservedObject var coordinator: NewShootCoordinator
    let modelContext: ModelContext
    var onDone: () -> Void

    @StateObject private var viewModel = GalleryResultViewModel()

    private var localURL: URL? { coordinator.generatedFileURL }

    private var uiImage: UIImage? {
        guard let localURL else { return nil }
        return UIImage(contentsOfFile: localURL.path)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                } else {
                    ContentUnavailableView("No image", systemImage: "photo")
                }

                VStack(spacing: 12) {
                    Button {
                        coordinator.resetFlow()
                        onDone()
                    } label: {
                        Text("Сгенерировать еще")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if let localURL {
                        ShareLink(item: localURL) {
                            Label("Поделиться", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    Button("Сохранить в фото") {
                        Task { await viewModel.saveToPhotoLibrary(image: uiImage) }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                    Button("Готово") {
                        coordinator.resetFlow()
                        onDone()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Step 3 of 3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            guard let localURL else { return }
            await viewModel.saveSessionIfNeeded(
                localURL: localURL,
                repository: dependencies.repository(context: modelContext),
                shootTitle: coordinator.selectedVibe?.rawValue
            )
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
