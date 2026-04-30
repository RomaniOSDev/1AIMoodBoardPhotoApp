//
//  GalleryResultView.swift
//  1AIMoodBoardPhotoApp
//

import StoreKit
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

    private var persistedShootTitle: String? {
        let t = coordinator.shootTitleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
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

                paywallPanel

                VStack(spacing: 12) {
                    Button {
                        guard let localURL, let uiImage else { return }
                        Task {
                            await viewModel.saveToMyPhotosAndLibrary(
                                localURL: localURL,
                                repository: dependencies.repository(context: modelContext),
                                image: uiImage,
                                shootTitle: persistedShootTitle
                            )
                        }
                    } label: {
                        Text("Save to My Photos")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if let localURL {
                        ShareLink(item: localURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    if dependencies.bananaManager.balance == 0 {
                        Button {
                            Task {
                                await purchaseBananas()
                            }
                        } label: {
                            Text("Buy more bananas")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(dependencies.storeKitManager.purchaseInProgress)
                    }

                    Button("Done") {
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
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private var paywallPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bananas left: \(dependencies.bananaManager.balance)")
                .font(.title3.bold())
            Text("Buy 10 bananas for \(formattedPrice) to keep creating.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                Task { await purchaseBananas() }
            } label: {
                Text("Buy 10 bananas – \(formattedPrice)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(dependencies.storeKitManager.purchaseInProgress)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .padding(.horizontal)
    }

    private var formattedPrice: String {
        if let product = dependencies.storeKitManager.products.first(where: { $0.id == Constants.bananaProductID }) {
            return product.displayPrice
        }
        return "$4.99"
    }

    private func purchaseBananas() async {
        do {
            try await dependencies.storeKitManager.purchaseBananaPack(bananaManager: dependencies.bananaManager)
        } catch let error as StoreError {
            if case .userCancelled = error {
                print("[GalleryResult] purchase cancelled")
                return
            }
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        } catch {
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        }
    }
}
