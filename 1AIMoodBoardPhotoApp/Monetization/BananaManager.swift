//
//  BananaManager.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import Combine

enum BananaError: LocalizedError {
    case insufficientFunds
    case keychainFailed(String)

    var errorDescription: String? {
        switch self {
        case .insufficientFunds: return L10n.AppStrings.notEnoughBananas
        case .keychainFailed(let message): return message
        }
    }
}

@MainActor
final class BananaManager: ObservableObject {
    static let shared = BananaManager()

    @Published private(set) var balance: Int = Constants.initialBananaBalance

    private init() {
        loadBalance()
    }

    private func loadBalance() {
        do {
            if let data = try KeychainHelper.load(
                service: Constants.BananaKeychain.service,
                account: Constants.BananaKeychain.account
            ), let string = String(data: data, encoding: .utf8), let value = Int(string) {
                balance = value
                print("[BananaManager] loaded balance=\(value)")
                return
            }
        } catch {
            print("[BananaManager] keychain load error: \(error)")
        }
        balance = Constants.initialBananaBalance
        persistBalance()
        print("[BananaManager] initialized default balance=\(balance)")
    }

    func persistBalance() {
        do {
            guard let data = String(balance).data(using: .utf8) else { return }
            try KeychainHelper.save(
                data: data,
                service: Constants.BananaKeychain.service,
                account: Constants.BananaKeychain.account
            )
        } catch {
            print("[BananaManager] persist error: \(error)")
        }
    }

    func chargeForGeneration() throws {
        guard balance >= Constants.generationCost else {
            throw BananaError.insufficientFunds
        }
        balance -= Constants.generationCost
        persistBalance()
        print("[BananaManager] charged 1, balance=\(balance)")
    }

    func refundGeneration() {
        balance += Constants.generationCost
        persistBalance()
        print("[BananaManager] refunded 1, balance=\(balance)")
    }

    func addPurchasedBananas(_ count: Int) {
        balance += count
        persistBalance()
        print("[BananaManager] added \(count), balance=\(balance)")
    }

    func resetToInitialBalance() {
        balance = Constants.initialBananaBalance
        persistBalance()
        print("[BananaManager] reset balance=\(balance)")
    }

    var totalBananasSpentStatistic: Int {
        UserDefaults.standard.integer(forKey: Constants.Stats.totalSpentKey)
    }

    func recordSuccessfulGenerationSpend() {
        let key = Constants.Stats.totalSpentKey
        let next = UserDefaults.standard.integer(forKey: key) + Constants.generationCost
        UserDefaults.standard.set(next, forKey: key)
        print("[BananaManager] recorded spend stat=\(next)")
    }
}
