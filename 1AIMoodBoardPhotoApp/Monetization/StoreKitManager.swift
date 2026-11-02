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

enum StoreProductKind: String, CaseIterable, Identifiable, Sendable {
    case weeklyTrial
    case weeklyNow
    case generations5

    var id: String { productID }

    var productID: String {
        switch self {
        case .weeklyTrial: return Constants.StoreProducts.weeklyTrial
        case .weeklyNow: return Constants.StoreProducts.weeklyNow
        case .generations5: return Constants.StoreProducts.generations5
        }
    }

    var isSubscription: Bool {
        switch self {
        case .weeklyTrial, .weeklyNow: return true
        case .generations5: return false
        }
    }
}

@MainActor
final class StoreKitManager: ObservableObject {
    @Published private(set) var isSubscribed = false
    @Published private(set) var isInIntroOfferPeriod = false
    @Published private(set) var isEligibleForIntroOffer = true
    @Published private(set) var productsByID: [String: Product] = [:]
    @Published private(set) var purchaseInProgress = false
    @Published private(set) var loadErrorMessage: String?

    /// Active subscription original transaction id (for credit sync).
    @Published private(set) var activeOriginalID: UInt64?
    /// Stable id for current paid billing period.
    @Published private(set) var activePeriodID: String?
    /// Product id of the active auto-renewable entitlement.
    @Published private(set) var activeSubscriptionProductID: String?

    private var updatesTask: Task<Void, Never>?
    private let credits: GenerationCredits

    init(credits: GenerationCredits = .shared) {
        self.credits = credits
        startTransactionListener()
        Task {
            await refreshEntitlements()
            await loadProducts()
        }
        Task {
            await finishUnfinishedConsumables()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: Set(Constants.StoreProducts.all))
            var map: [String: Product] = [:]
            for product in products {
                map[product.id] = product
            }
            productsByID = map
            print("[StoreKit] loaded: \(products.map(\.id).sorted())")

            let missing = Set(Constants.StoreProducts.all).subtracting(map.keys)
            if map.isEmpty {
                loadErrorMessage = L10n.StoreKitConfig.noProductsLoaded
            } else if !missing.isEmpty {
                print("[StoreKit] missing product IDs: \(missing.sorted())")
                loadErrorMessage = missing.count == Constants.StoreProducts.all.count
                    ? L10n.StoreKitConfig.noProductsLoaded
                    : nil
            } else {
                loadErrorMessage = nil
            }

            if let trial = product(for: .weeklyTrial) {
                await refreshIntroOfferEligibility(for: trial)
            } else {
                isEligibleForIntroOffer = false
            }

            // Status API gives a more reliable intro/paid signal than offerType alone.
            await refreshEntitlements()
        } catch {
            loadErrorMessage = error.localizedDescription
            print("[StoreKit] loadProducts error: \(error)")
        }
    }

    private func refreshIntroOfferEligibility(for product: Product) async {
        guard let subscription = product.subscription else {
            isEligibleForIntroOffer = false
            return
        }
        isEligibleForIntroOffer = await subscription.isEligibleForIntroOffer
    }

    func product(for kind: StoreProductKind) -> Product? {
        productsByID[kind.productID]
    }

    func isProductAvailable(_ kind: StoreProductKind) -> Bool {
        product(for: kind) != nil
    }

    func displayPrice(for kind: StoreProductKind) -> String {
        product(for: kind)?.displayPrice ?? "—"
    }

    var hasAnyPurchasableProduct: Bool {
        StoreProductKind.allCases.contains { isProductAvailable($0) }
    }

    func purchase(_ kind: StoreProductKind) async throws {
        if productsByID.isEmpty {
            await loadProducts()
        }
        guard let product = product(for: kind) else {
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
            await handle(transaction: transaction)
            await transaction.finish()
            // Re-check status after upgrade / intro → paid.
            await refreshEntitlements()
            print("[StoreKit] purchase success id=\(transaction.id) product=\(transaction.productID) intro=\(isInIntroOfferPeriod)")
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
        var inIntro = false
        var originalID: UInt64?
        var periodID: String?
        var productID: String?

        // Prefer subscription status (includes offer period reliably).
        if let statusInfo = await activeSubscriptionStatus() {
            active = true
            productID = statusInfo.transaction.productID
            originalID = statusInfo.transaction.originalID
            inIntro = statusInfo.isIntro
            if let expiration = statusInfo.transaction.expirationDate {
                periodID = "\(statusInfo.transaction.originalID)-\(Int(expiration.timeIntervalSince1970))"
            } else {
                periodID = "\(statusInfo.transaction.originalID)-\(statusInfo.transaction.id)"
            }
        } else {
            for await result in Transaction.currentEntitlements {
                guard let transaction = try? checkVerified(result) else { continue }
                guard transaction.productType == .autoRenewable else { continue }
                guard Constants.StoreProducts.allSubscriptionIDs.contains(transaction.productID) else { continue }
                guard transaction.revocationDate == nil else { continue }

                active = true
                productID = transaction.productID
                originalID = transaction.originalID
                inIntro = Self.isIntroductory(transaction: transaction)
                if let expiration = transaction.expirationDate {
                    periodID = "\(transaction.originalID)-\(Int(expiration.timeIntervalSince1970))"
                } else {
                    periodID = "\(transaction.originalID)-\(transaction.id)"
                }
                break
            }
        }

        isSubscribed = active
        isInIntroOfferPeriod = active && inIntro
        activeOriginalID = originalID
        activePeriodID = periodID
        activeSubscriptionProductID = productID

        credits.syncWithSubscription(
            isSubscribed: active,
            isInIntroOffer: isInIntroOfferPeriod,
            originalID: originalID,
            periodID: isInIntroOfferPeriod ? nil : periodID
        )

        print("[StoreKit] entitlements refreshed, isSubscribed=\(active) intro=\(isInIntroOfferPeriod) product=\(productID ?? "nil")")
    }

    private struct ActiveSubscriptionStatus {
        let transaction: Transaction
        let isIntro: Bool
    }

    private func activeSubscriptionStatus() async -> ActiveSubscriptionStatus? {
        let candidates = [product(for: .weeklyNow), product(for: .weeklyTrial)].compactMap { $0 }
        for product in candidates {
            guard let statuses = try? await product.subscription?.status else { continue }
            for status in statuses {
                guard case .verified(let transaction) = status.transaction else { continue }
                guard Constants.StoreProducts.allSubscriptionIDs.contains(transaction.productID) else { continue }
                guard transaction.revocationDate == nil else { continue }
                guard status.state == .subscribed || status.state == .inGracePeriod || status.state == .inBillingRetryPeriod else {
                    continue
                }

                var isIntro = Self.isIntroductory(transaction: transaction)
                if case .verified(let renewal) = status.renewalInfo {
                    // If renewing into a paid period but current tx still has intro offer — still intro.
                    // If offerType on renewal is nil and transaction has no intro — paid.
                    if renewal.offerType == .introductory {
                        isIntro = true
                    }
                }
                // Active entitlement on the trial SKU with a short remaining window ≈ intro.
                if !isIntro,
                   transaction.productID == Constants.StoreProducts.weeklyTrial,
                   let expiration = transaction.expirationDate {
                    let remaining = expiration.timeIntervalSinceNow
                    // Free trial is 3 days; paid week is 7. Treat < 4 days remaining on trial SKU as intro.
                    if remaining > 0, remaining < 4 * 24 * 60 * 60 {
                        isIntro = true
                    }
                }

                return ActiveSubscriptionStatus(transaction: transaction, isIntro: isIntro)
            }
        }
        return nil
    }

    private static func isIntroductory(transaction: Transaction) -> Bool {
        if transaction.offerType == .introductory { return true }
        // Fallback: trial SKU + expiration within ~3–4 days of purchase.
        if transaction.productID == Constants.StoreProducts.weeklyTrial,
           let expiration = transaction.expirationDate {
            let span = expiration.timeIntervalSince(transaction.purchaseDate)
            if span > 0, span <= 4 * 24 * 60 * 60 {
                return true
            }
        }
        return false
    }

    private func handle(transaction: Transaction) async {
        if transaction.productType == .consumable,
           transaction.productID == Constants.StoreProducts.generations5 {
            credits.addConsumablePack(fromTransactionID: transaction.id)
        }
        await refreshEntitlements()
    }

    private func finishUnfinishedConsumables() async {
        for await result in Transaction.unfinished {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productType == .consumable,
               transaction.productID == Constants.StoreProducts.generations5 {
                credits.addConsumablePack(fromTransactionID: transaction.id)
            }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    private func startTransactionListener() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.handle(transaction: transaction)
                    await transaction.finish()
                } catch {
                    print("[StoreKit] updates verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified:
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
