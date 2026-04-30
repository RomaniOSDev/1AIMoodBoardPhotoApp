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

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
