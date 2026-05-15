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

enum BananaPack: CaseIterable, Identifiable, Sendable {
    case five
    case ten
    case thirty

    var id: String { productID }

    var productID: String {
        switch self {
        case .five: return Constants.BananaProducts.five
        case .ten: return Constants.BananaProducts.ten
        case .thirty: return Constants.BananaProducts.thirty
        }
    }

    var bananas: Int {
        switch self {
        case .five: return 5
        case .ten: return 10
        case .thirty: return 30
        }
    }

    var fallbackPrice: String {
        switch self {
        case .five: return "$2.99"
        case .ten: return "$4.99"
        case .thirty: return "$12.99"
        }
    }

    var title: String { L10n.Store.packTitle(bananas: bananas) }
}

@MainActor
final class StoreKitManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress = false
    @Published private(set) var loadErrorMessage: String?

    private let productIDs = Constants.BananaProducts.all
    private let bananaManager: BananaManager
    private var updatesTask: Task<Void, Never>?
    private var processedTransactionIDs: Set<String>
    private static let processedTransactionsKey = "storekit_processed_transaction_ids"

    init(bananaManager: BananaManager) {
        self.bananaManager = bananaManager
        self.processedTransactionIDs = Set(UserDefaults.standard.stringArray(forKey: Self.processedTransactionsKey) ?? [])
        startTransactionListener()
        Task {
            await syncUnfinishedTransactions()
            await loadProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            print("[StoreKit] requested productIDs=\(productIDs)")
            print("[StoreKit] loaded products: \(products.map(\.id))")
            if products.isEmpty {
                loadErrorMessage = L10n.StoreKitConfig.noProductsLoaded
                print("[StoreKit] warning: no products loaded. Check Scheme -> Run -> Options -> StoreKit Configuration and product ids.")
            } else {
                loadErrorMessage = nil
            }
        } catch {
            loadErrorMessage = error.localizedDescription
            print("[StoreKit] loadProducts error: \(error)")
        }
    }

    func purchaseBananaPack() async throws {
        try await purchase(pack: .ten)
    }

    func purchase(pack: BananaPack) async throws {
        if products.isEmpty {
            await loadProducts()
        }
        guard let product = products.first(where: { $0.id == pack.productID }) else {
            throw StoreError.purchaseFailed("Product `\(pack.productID)` is unavailable. Verify StoreKit configuration is attached to the scheme.")
        }
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result: Product.PurchaseResult
        if let scene = activeWindowScene() {
            result = try await product.purchase(confirmIn: scene)
        } else {
            print("[StoreKit] warning: no active UIWindowScene for purchase; falling back to purchase()")
            result = try await product.purchase()
        }
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await handleVerifiedTransaction(transaction, source: "purchase")
            print("[StoreKit] purchase success id=\(transaction.id)")
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            throw StoreError.purchaseFailed("Purchase is pending approval.")
        @unknown default:
            throw StoreError.purchaseFailed("Unknown purchase result.")
        }
    }

    func displayPrice(for pack: BananaPack) -> String {
        products.first(where: { $0.id == pack.productID })?.displayPrice ?? pack.fallbackPrice
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        print("[StoreKit] AppStore.sync completed (restore). User may re-download consumables via developer policy — balance updates on successful purchase only.)")
    }

    private func syncUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            do {
                let transaction = try checkVerified(result)
                await handleVerifiedTransaction(transaction, source: "unfinished")
            } catch {
                print("[StoreKit] unfinished verification failed: \(error)")
            }
        }
    }

    private func startTransactionListener() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.handleVerifiedTransaction(transaction, source: "updates")
                } catch {
                    print("[StoreKit] updates verification failed: \(error)")
                }
            }
        }
    }

    private func handleVerifiedTransaction(_ transaction: Transaction, source: String) async {
        let id = String(transaction.id)
        let wasProcessed = processedTransactionIDs.contains(id)

        if !wasProcessed {
            if let pack = BananaPack.allCases.first(where: { $0.productID == transaction.productID }) {
                bananaManager.addPurchasedBananas(pack.bananas)
                print("[StoreKit] delivered bananas=\(pack.bananas) tx=\(transaction.id) source=\(source)")
            } else {
                print("[StoreKit] ignoring non-banana product id=\(transaction.productID) tx=\(transaction.id)")
            }
            markTransactionProcessed(id)
        } else {
            print("[StoreKit] already processed tx=\(transaction.id) source=\(source)")
        }

        await transaction.finish()
    }

    private func markTransactionProcessed(_ id: String) {
        processedTransactionIDs.insert(id)
        // Keep persistence bounded in case of many test purchases.
        let trimmed = Array(processedTransactionIDs.suffix(300))
        processedTransactionIDs = Set(trimmed)
        UserDefaults.standard.set(Array(processedTransactionIDs), forKey: Self.processedTransactionsKey)
    }

    private func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified(_, let error):
            print("[StoreKit] unverified: \(error)")
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
