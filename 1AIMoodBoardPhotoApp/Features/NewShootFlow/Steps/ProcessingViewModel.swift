//
//  ProcessingViewModel.swift
//  1AIMoodBoardPhotoApp
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class ProcessingViewModel: ObservableObject {
    enum StatusMessage: String {
        case uploading = "Uploading photos..."
        case ai = "AI is creating your style..."
        case almost = "Almost ready..."
    }

    @Published var message: StatusMessage = .uploading
    @Published var progress: Double = 0.15
    @Published var showAlert = false
    @Published var alertTitle = "Error"
    @Published var alertMessage = ""
    @Published var isRunning = true
    @Published private(set) var completedSuccessfully = false

    private var hasStarted = false

    func startIfNeeded(
        dependencies: AppDependencies,
        coordinator: NewShootCoordinator,
        onSuccess: @escaping () -> Void
    ) async {
        guard !hasStarted else { return }
        hasStarted = true
        await runPipeline(dependencies: dependencies, coordinator: coordinator, onSuccess: onSuccess)
    }

    func retry(
        dependencies: AppDependencies,
        coordinator: NewShootCoordinator,
        onSuccess: @escaping () -> Void
    ) async {
        completedSuccessfully = false
        isRunning = true
        progress = 0.15
        message = .uploading
        await runPipeline(dependencies: dependencies, coordinator: coordinator, onSuccess: onSuccess)
    }

    private func runPipeline(
        dependencies: AppDependencies,
        coordinator: NewShootCoordinator,
        onSuccess: @escaping () -> Void
    ) async {
        isRunning = true
        var charged = false

        do {
            try dependencies.bananaManager.chargeForGeneration()
            charged = true

            message = .uploading
            progress = 0.25

            message = .ai
            progress = 0.55

            let url = try await dependencies.aiService.generateShoot(
                selfieImages: coordinator.selfieImages,
                stylePreset: coordinator.selectedVibe,
                referenceImage: coordinator.referenceStyleImage
            )

            message = .almost
            progress = 0.95

            coordinator.generatedFileURL = url
            dependencies.bananaManager.recordSuccessfulGenerationSpend()

            charged = false
            progress = 1.0
            completedSuccessfully = true
            isRunning = false
            print("[ProcessingViewModel] success path=\(url.path)")
            onSuccess()
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
                alertTitle = "Couldn't generate"
                alertMessage =
                    "The provider flagged this request. Try another selfie, a different vibe, or a neutral background."
            } else {
                alertTitle = "Couldn't generate"
                alertMessage = detail.isEmpty ? (error.errorDescription ?? "") : detail
            }
        default:
            alertTitle = "Error"
            alertMessage = error.errorDescription ?? String(describing: error)
        }
        showAlert = true
    }

    private func present(error: LocalizedError) {
        alertTitle = "Error"
        alertMessage = error.errorDescription ?? String(describing: error)
        showAlert = true
    }

    private func present(message: String) {
        alertTitle = "Error"
        alertMessage = message
        showAlert = true
    }
}
