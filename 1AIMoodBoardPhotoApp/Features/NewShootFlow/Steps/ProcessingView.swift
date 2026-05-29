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
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isRunning {
                    Button(L10n.Processing.cancel, role: .cancel) {
                        cancelAndGoBack()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActions
        }
        .task {
            guard autoStartGeneration else { return }
            guard AIProcessingConsent.hasGranted else {
                coordinator.pop()
                return
            }
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
            Button(L10n.Processing.cancel, role: .cancel) {
                cancelAndGoBack()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    @ViewBuilder
    private var bottomActions: some View {
        Group {
            if viewModel.isRunning {
                processingSecondaryButton(title: L10n.Processing.cancel, action: cancelAndGoBack)
            } else if !viewModel.completedSuccessfully {
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await viewModel.retry(
                                dependencies: dependencies,
                                coordinator: coordinator,
                                onSuccess: {
                                    coordinator.push(.galleryResult)
                                }
                            )
                        }
                    } label: {
                        CustomButtonView(text: L10n.Common.tryAgain)
                    }
                    .buttonStyle(.plain)

                    processingSecondaryButton(title: L10n.Processing.cancel, action: cancelAndGoBack)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 28)
        .safeAreaPadding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .background(processingBottomScrim)
    }

    private var processingBottomScrim: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0),
                Color.black.opacity(0.45),
                Color.black.opacity(0.72)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .bottom)
    }

    private func processingSecondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.custom(17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color.white.opacity(0.32), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func cancelAndGoBack() {
        viewModel.cancelGeneration()
        coordinator.pop()
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        Group {
            if let source = backgroundImage {
                Image(uiImage: source)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .blur(radius: 28)
                    .overlay(Color.black.opacity(0.35))
            } else {
                Color.black.opacity(0.85)
            }
        }
        .ignoresSafeArea()
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
