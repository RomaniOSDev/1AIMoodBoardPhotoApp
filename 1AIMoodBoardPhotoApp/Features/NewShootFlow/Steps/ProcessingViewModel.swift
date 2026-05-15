//
//  ProcessingViewModel.swift
//  1AIMoodBoardPhotoApp
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class ProcessingViewModel: ObservableObject {
    @Published var message: String = L10n.Progress.preparing
    @Published var progress: Double = 0.15
    @Published var showAlert = false
    @Published var alertTitle = L10n.Common.error
    @Published var alertMessage = ""
    @Published var isRunning = true
    @Published private(set) var completedSuccessfully = false

    private var hasStarted = false
    private var currentTask: Task<Void, Never>?

    func startIfNeeded(
        dependencies: AppDependencies,
        coordinator: NewShootCoordinator,
        onSuccess: @escaping () -> Void
    ) async {
        guard !hasStarted else { return }
        hasStarted = true
        startPipelineTask(dependencies: dependencies, coordinator: coordinator, onSuccess: onSuccess)
    }

    func retry(
        dependencies: AppDependencies,
        coordinator: NewShootCoordinator,
        onSuccess: @escaping () -> Void
    ) async {
        currentTask?.cancel()
        completedSuccessfully = false
        isRunning = true
        progress = 0.15
        message = L10n.Progress.preparing
        startPipelineTask(dependencies: dependencies, coordinator: coordinator, onSuccess: onSuccess)
    }

    func cancelGeneration() {
        currentTask?.cancel()
    }

    private func startPipelineTask(
        dependencies: AppDependencies,
        coordinator: NewShootCoordinator,
        onSuccess: @escaping () -> Void
    ) {
        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self else { return }
            await self.runPipeline(dependencies: dependencies, coordinator: coordinator, onSuccess: onSuccess)
        }
    }

    private func runPipeline(
        dependencies: AppDependencies,
        coordinator: NewShootCoordinator,
        onSuccess: @escaping () -> Void
    ) async {
        defer { currentTask = nil }
        isRunning = true
        var charged = false

        do {
            try dependencies.bananaManager.chargeForGeneration()
            charged = true

            let url = try await dependencies.aiService.generateShoot(
                selfieImages: coordinator.selfieImages,
                stylePreset: coordinator.selectedVibe,
                customPrompt: coordinator.customPrompt,
                onProgress: { [weak self] update in
                    Task { @MainActor in
                        guard let self else { return }
                        self.progress = min(max(update.value, 0), 1)
                        self.message = update.label
                    }
                }
            )

            coordinator.generatedFileURL = url
            dependencies.bananaManager.recordSuccessfulGenerationSpend()

            charged = false
            progress = 1.0
            message = L10n.Progress.done
            completedSuccessfully = true
            isRunning = false
            print("[ProcessingViewModel] success path=\(url.path)")
            // Keep 100% visible briefly before navigation.
            try? await Task.sleep(nanoseconds: 350_000_000)
            onSuccess()
        } catch is CancellationError {
            if charged { dependencies.bananaManager.refundGeneration() }
            charged = false
            isRunning = false
            print("[ProcessingViewModel] cancelled")
        } catch let error as BananaError {
            if charged { dependencies.bananaManager.refundGeneration() }
            charged = false
            isRunning = false
            present(error: error)
            print("[ProcessingViewModel] banana error: \(error)")
        } catch let error as AIError {
            if charged { dependencies.bananaManager.refundGeneration() }
            charged = false
            isRunning = false
            present(aiError: error)
            print("[ProcessingViewModel] AI error: \(error)")
        } catch {
            if charged { dependencies.bananaManager.refundGeneration() }
            charged = false
            isRunning = false
            present(message: error.localizedDescription)
            print("[ProcessingViewModel] error: \(error)")
        }
    }

    private func present(aiError error: AIError) {
        switch error {
        case .predictionFailed(let detail):
            let lower = detail.lowercased()
            if lower.contains("sensitive") || lower.contains("flagged") || lower.contains("nsfw") {
                alertTitle = L10n.Alerts.couldntGenerate
                alertMessage = L10n.Alerts.flaggedRequest
            } else {
                alertTitle = L10n.Alerts.couldntGenerate
                alertMessage = detail.isEmpty ? (error.errorDescription ?? "") : detail
            }
        default:
            alertTitle = L10n.Common.error
            alertMessage = error.errorDescription ?? String(describing: error)
        }
        showAlert = true
    }

    private func present(error: LocalizedError) {
        alertTitle = L10n.Common.error
        alertMessage = error.errorDescription ?? String(describing: error)
        showAlert = true
    }

    private func present(message: String) {
        alertTitle = L10n.Common.error
        alertMessage = message
        showAlert = true
    }
}
