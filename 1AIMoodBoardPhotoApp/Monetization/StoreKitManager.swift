//
//  StoreKitManager.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import StoreKit
import Combine

enum StoreError: LocalizedError {
    case productUnavailable
    case purchaseFailed(String)
    case verificationFailed
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .productUnavailable: return "Product is unavailable."
        case .purchaseFailed(let message): return message
        case .verificationFailed: return "Purchase verification failed."
        case .userCancelled: return "Purchase cancelled."
        }
    }
}

@MainActor
final class StoreKitManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress = false

    private let productIDs = [Constants.bananaProductID]

    init() {
        Task { await loadProducts() }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            print("[StoreKit] requested productIDs=\(productIDs)")
            print("[StoreKit] loaded products: \(products.map(\.id))")
            if products.isEmpty {
                print("[StoreKit] warning: no products loaded. Check Scheme -> Run -> Options -> StoreKit Configuration and product ids.")
            }
        } catch {
            print("[StoreKit] loadProducts error: \(error)")
        }
    }

    func purchaseBananaPack(bananaManager: BananaManager) async throws {
        if products.isEmpty {
            await loadProducts()
        }
        guard let product = products.first(where: { $0.id == Constants.bananaProductID }) else {
            throw StoreError.purchaseFailed("Product `\(Constants.bananaProductID)` is unavailable. Verify StoreKit configuration is attached to the scheme.")
        }
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await deliverBananas(bananaManager: bananaManager)
            await transaction.finish()
            print("[StoreKit] purchase success id=\(transaction.id)")
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            throw StoreError.purchaseFailed("Purchase is pending approval.")
        @unknown default:
            throw StoreError.purchaseFailed("Unknown purchase result.")
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        print("[StoreKit] AppStore.sync completed (restore). User may re-download consumables via developer policy — balance updates on successful purchase only.)")
    }

    private func deliverBananas(bananaManager: BananaManager) async {
        bananaManager.addPurchasedBananas(10)
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
}
