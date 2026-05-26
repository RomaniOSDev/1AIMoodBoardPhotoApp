//
//  StoreKitManager.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import StoreKit
import Combine
import UIKit

enum StoreError: LocalizedError {
    case productUnavailable
    case purchaseFailed(String)
    case verificationFailed
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .productUnavailable: return L10n.Store.errorUnavailable
        case .purchaseFailed(let message): return message
        case .verificationFailed: return L10n.Store.errorVerifyFailed
        case .userCancelled: return L10n.Store.errorCancelled
        }
    }
}

enum WeeklySubscriptionPlan: String, CaseIterable, Identifiable, Sendable {
    case trial
    case noTrial

    var id: String { productID }

    var productID: String {
        switch self {
        case .trial: return Constants.SubscriptionProducts.weeklyWithTrial
        case .noTrial: return Constants.SubscriptionProducts.weeklyNoTrial
        }
    }
}

@MainActor
final class StoreKitManager: ObservableObject {
    @Published private(set) var isSubscribed = false
    @Published private(set) var subscriptionProducts: [Product] = []
    @Published private(set) var purchaseInProgress = false
    @Published private(set) var loadErrorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        startTransactionListener()
        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        do {
            subscriptionProducts = try await Product.products(for: Constants.SubscriptionProducts.all)
            print("[StoreKit] loaded: \(subscriptionProducts.map(\.id))")
            if subscriptionProducts.isEmpty {
                loadErrorMessage = L10n.StoreKitConfig.noProductsLoaded
            } else {
                loadErrorMessage = nil
            }
        } catch {
            loadErrorMessage = error.localizedDescription
            print("[StoreKit] loadProducts error: \(error)")
        }
    }

    func product(for plan: WeeklySubscriptionPlan) -> Product? {
        subscriptionProducts.first { $0.id == plan.productID }
    }

    func displayPrice(for plan: WeeklySubscriptionPlan) -> String {
        product(for: plan)?.displayPrice ?? "—"
    }

    func purchase(plan: WeeklySubscriptionPlan) async throws {
        if subscriptionProducts.isEmpty {
            await loadProducts()
        }
        guard let product = product(for: plan) else {
            throw StoreError.productUnavailable
        }

        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result: Product.PurchaseResult
        if let scene = activeWindowScene() {
            result = try await product.purchase(confirmIn: scene)
        } else {
            result = try await product.purchase()
        }

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await refreshEntitlements()
            await transaction.finish()
            print("[StoreKit] purchase success id=\(transaction.id) product=\(transaction.productID)")
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            throw StoreError.purchaseFailed(L10n.Store.purchasePending)
        @unknown default:
            throw StoreError.purchaseFailed(L10n.Store.purchaseUnknown)
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
        print("[StoreKit] restore completed, isSubscribed=\(isSubscribed)")
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.productType == .autoRenewable else { continue }
            guard Constants.SubscriptionProducts.all.contains(transaction.productID) else { continue }
            if transaction.revocationDate == nil {
                active = true
                break
            }
        }
        isSubscribed = active
        print("[StoreKit] entitlements refreshed, isSubscribed=\(active)")
    }

    private func startTransactionListener() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.refreshEntitlements()
                    await transaction.finish()
                } catch {
                    print("[StoreKit] updates verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified(_, let error):
            throw StoreError.verificationFailed
        case .verified(let transaction):
            return transaction
        }
    }

    private func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}
