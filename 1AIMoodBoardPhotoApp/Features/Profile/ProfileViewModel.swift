//
//  ProfileViewModel.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import SwiftData
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var showPurchaseError = false
    @Published var purchaseErrorMessage = ""
    @Published var showRestoreAlert = false
    @Published var restoreMessage = ""
    @Published var showResetAlert = false
    @Published var resetMessage = ""

    func purchase(pack: BananaPack, dependencies: AppDependencies) async {
        do {
            try await dependencies.storeKitManager.purchase(pack: pack)
        } catch let error as StoreError {
            if case .userCancelled = error { return }
            purchaseErrorMessage = error.localizedDescription
            showPurchaseError = true
        } catch {
            purchaseErrorMessage = error.localizedDescription
            showPurchaseError = true
        }
    }

    func restore(dependencies: AppDependencies) async {
        do {
            try await dependencies.storeKitManager.restorePurchases()
            restoreMessage = "Sync finished. For consumables (bananas), automatic restore is limited by Apple policy."
            showRestoreAlert = true
        } catch {
            restoreMessage = error.localizedDescription
            showRestoreAlert = true
        }
    }

    func generationCount(repository: ShootRepository) -> Int {
        (try? repository.fetchAllPhotosSorted().count) ?? 0
    }

    func resetAllData(dependencies: AppDependencies, modelContext: ModelContext) async -> Bool {
        do {
            try dependencies.repository(context: modelContext).resetAllData()
            dependencies.bananaManager.resetToInitialBalance()
            UserDefaults.standard.set(0, forKey: Constants.Stats.totalSpentKey)
            UserDefaults.standard.set(false, forKey: Constants.onboardingCompletedKey)
            resetMessage = "All app data has been reset."
            showResetAlert = true
            return true
        } catch {
            resetMessage = error.localizedDescription
            showResetAlert = true
            return false
        }
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
