//
//  ProcessingView.swift
//  1AIMoodBoardPhotoApp
//

import Combine
import SwiftUI

struct ProcessingView: View {
    let dependencies: AppDependencies
    @ObservedObject var coordinator: NewShootCoordinator
    private let autoStartGeneration: Bool

    @StateObject private var viewModel = ProcessingViewModel()

    @MainActor
    init(dependencies: AppDependencies, coordinator: NewShootCoordinator) {
        self.dependencies = dependencies
        self.coordinator = coordinator
        self.autoStartGeneration = true
        _viewModel = StateObject(wrappedValue: ProcessingViewModel())
    }

    @MainActor
    init(
        dependencies: AppDependencies,
        coordinator: NewShootCoordinator,
        viewModel: ProcessingViewModel,
        autoStartGeneration: Bool
    ) {
        self.dependencies = dependencies
        self.coordinator = coordinator
        self.autoStartGeneration = autoStartGeneration
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            
            backgroundLayer

            VStack {
                Spacer()

                progressCenter

                Spacer()

                if viewModel.isRunning {
                    Button(role: .cancel) {
                        viewModel.cancelGeneration()
                        coordinator.pop()
                    } label: {
                        Text(L10n.Processing.cancel)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.pinkApp)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
                } else if !viewModel.completedSuccessfully {
                    
                    Button(L10n.Common.tryAgain) {
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
                    .padding(.bottom, 18)
                }
                
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task {
            guard autoStartGeneration else { return }
            await viewModel.startIfNeeded(
                dependencies: dependencies,
                coordinator: coordinator,
                onSuccess: {
                    coordinator.push(.galleryResult)
                }
            )
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button(L10n.Common.tryAgain) {
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
            Button(L10n.Common.cancel, role: .cancel) {
                coordinator.pop()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    @ViewBuilder private var backgroundLayer: some View {
        if let source = backgroundImage {
            Image(uiImage: source)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 28)
                .overlay(Color.black.opacity(0.18))
        } else {
            Color.black.opacity(0.85)
        }
    }

    private var backgroundImage: UIImage? {
        if let selfie = coordinator.selfieImages.first {
            return selfie
        }
        if let asset = UIImage(named: "pre1") {
            return asset
        }
        return nil
    }

    private var progressCenter: some View {
        VStack(spacing: 14) {
            ZStack {

                Circle()
                    .trim(from: 0, to: max(min(viewModel.progress, 1), 0))
                    .stroke(
                        Color.pinkApp,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 138, height: 138)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.25), value: viewModel.progress)

                Text("\(Int((max(min(viewModel.progress, 1), 0) * 100).rounded()))%")
                    .font(.system(size: 30, weight: .light, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            Text(viewModel.message)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.center)
        }
        .padding(20)
    }
}

#Preview {
    let dependencies = AppDependencies()
    let coordinator = NewShootCoordinator()
    let viewModel = ProcessingViewModel()
    viewModel.progress = 0.5
    viewModel.message = L10n.Progress.generating
    viewModel.isRunning = true

    return ProcessingView(
        dependencies: dependencies,
        coordinator: coordinator,
        viewModel: viewModel,
        autoStartGeneration: false
    )
}
