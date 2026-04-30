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
    var saveOnAppear: Bool = true

    @StateObject private var viewModel = GalleryResultViewModel()

    private var localURL: URL? { coordinator.generatedFileURL }

    private var uiImage: UIImage? {
        guard let localURL else { return nil }
        return UIImage(contentsOfFile: localURL.path)
    }

    var body: some View {
        ZStack{
            Color.backMain.ignoresSafeArea()
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
                            CustomButtonView(text: "Generate New")
                            
                        }
                        
                        
                        if let localURL {
                            ShareLink(item: localURL) {
                                CustomButtonView(image: "square.and.arrow.up", text: "Share")
                                
                            }
                        }
                        
                        Button {
                            Task { await viewModel.saveToPhotoLibrary(image: uiImage) }
                        } label: {
                            CustomButtonView(text: "Save to Photos")
                            
                        }
                        
                        Button {
                            coordinator.resetFlow()
                            onDone()
                        } label: {
                            CustomButtonView(text: "Close")
                            
                        }
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
                guard saveOnAppear else { return }
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
}

private enum GalleryResultPreviewFactory {
    static func makeImageFileURL() -> URL? {
        guard let previewImage = UIImage(named: "pre1"), let data = previewImage.pngData() else {
            return nil
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("preview_generated.png")
        try? data.write(to: outputURL, options: .atomic)
        return outputURL
    }
}

private struct GalleryResultPreviewHost: View {
    let dependencies = AppDependencies()
    @StateObject private var coordinator: NewShootCoordinator

    init() {
        let c = NewShootCoordinator()
        c.selectedVibe = .coastal
        c.generatedFileURL = GalleryResultPreviewFactory.makeImageFileURL()
        _coordinator = StateObject(wrappedValue: c)
    }

    var body: some View {
        NavigationStack {
            GalleryResultView(
                dependencies: dependencies,
                coordinator: coordinator,
                modelContext: dependencies.persistence.container.mainContext,
                onDone: {},
                saveOnAppear: false
            )
        }
        .environmentObject(dependencies)
        .modelContainer(dependencies.persistence.container)
    }
}

#Preview("Gallery Result") {
    GalleryResultPreviewHost()
}
