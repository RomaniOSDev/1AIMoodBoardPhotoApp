//
//  ProcessingView.swift
//  1AIMoodBoardPhotoApp
//

import Combine
import SwiftUI

struct ProcessingView: View {
    let dependencies: AppDependencies
    @ObservedObject var coordinator: NewShootCoordinator

    @StateObject private var viewModel = ProcessingViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🍌")
                .font(.system(size: 56))

            ProgressView(value: viewModel.progress, total: 1.0)
                .tint(.yellow)
                .padding(.horizontal, 32)

            Text(viewModel.message.rawValue)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            if !viewModel.isRunning, !viewModel.completedSuccessfully {
                Button("Try again") {
                    Task {
                        await viewModel.retry(
                            dependencies: dependencies,
                            coordinator: coordinator,
                            onSuccess: {
                                coordinator.push(.galleryResult)
                            }
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Generating...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            await viewModel.startIfNeeded(
                dependencies: dependencies,
                coordinator: coordinator,
                onSuccess: {
                    coordinator.push(.galleryResult)
                }
            )
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("Try again") {
                Task {
                    await viewModel.retry(
                        dependencies: dependencies,
                        coordinator: coordinator,
                        onSuccess: {
                            coordinator.push(.galleryResult)
                        }
                    )
                }
            }
            Button("Cancel", role: .cancel) {
                coordinator.pop()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}
