//
//  GenerationCredits.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import Combine

enum GenerationCreditError: LocalizedError {
    case noCredits

    var errorDescription: String? {
        switch self {
        case .noCredits:
            return L10n.Paywall.noCreditsLeft
        }
    }
}

/// Local counters for trial / weekly / consumable generations.
/// Subscription status and prices always come from StoreKit; this only tracks usage.
@MainActor
final class GenerationCredits: ObservableObject {
    static let shared = GenerationCredits()

    @Published private(set) var consumableBalance: Int = 0
    @Published private(set) var trialUsed: Int = 0
    @Published private(set) var weeklyUsed: Int = 0

    private var trialOriginalID: String?
    private var weeklyPeriodID: String?

    private init() {
        consumableBalance = max(0, UserDefaults.standard.integer(forKey: Constants.CreditsStorage.consumableBalanceKey))
        trialUsed = max(0, UserDefaults.standard.integer(forKey: Constants.CreditsStorage.trialUsedKey))
        weeklyUsed = max(0, UserDefaults.standard.integer(forKey: Constants.CreditsStorage.weeklyUsedKey))
        trialOriginalID = UserDefaults.standard.string(forKey: Constants.CreditsStorage.trialOriginalIDKey)
        weeklyPeriodID = UserDefaults.standard.string(forKey: Constants.CreditsStorage.weeklyPeriodKey)
    }

    func subscriptionCreditsRemaining(isSubscribed: Bool, isInIntroOffer: Bool) -> Int {
        guard isSubscribed else { return 0 }
        if isInIntroOffer {
            return max(0, Constants.GenerationLimits.trial - trialUsed)
        }
        return max(0, Constants.GenerationLimits.weekly - weeklyUsed)
    }

    func remainingCredits(isSubscribed: Bool, isInIntroOffer: Bool) -> Int {
        subscriptionCreditsRemaining(isSubscribed: isSubscribed, isInIntroOffer: isInIntroOffer) + consumableBalance
    }

    func canGenerate(isSubscribed: Bool, isInIntroOffer: Bool) -> Bool {
        remainingCredits(isSubscribed: isSubscribed, isInIntroOffer: isInIntroOffer) > 0
    }

    /// Sync trial / weekly counters with the active StoreKit entitlement.
    func syncWithSubscription(
        isSubscribed: Bool,
        isInIntroOffer: Bool,
        originalID: UInt64?,
        periodID: String?
    ) {
        guard isSubscribed else { return }

        if isInIntroOffer {
            let idString = originalID.map(String.init)
            if let idString, trialOriginalID != idString {
                trialOriginalID = idString
                trialUsed = 0
                persistTrial()
            }
        } else if let periodID {
            if weeklyPeriodID != periodID {
                weeklyPeriodID = periodID
                weeklyUsed = 0
                persistWeekly()
            }
        }
    }

    /// Credits a consumable pack once per StoreKit transaction id.
    @discardableResult
    func addConsumablePack(fromTransactionID transactionID: UInt64) -> Bool {
        var processed = Set(UserDefaults.standard.stringArray(forKey: Constants.CreditsStorage.processedConsumableIDsKey) ?? [])
        let key = String(transactionID)
        guard !processed.contains(key) else {
            print("[GenerationCredits] skip duplicate consumable tx=\(key)")
            return false
        }
        processed.insert(key)
        // Keep the list bounded.
        if processed.count > 200 {
            processed = Set(processed.suffix(100))
        }
        UserDefaults.standard.set(Array(processed), forKey: Constants.CreditsStorage.processedConsumableIDsKey)
        consumableBalance += Constants.GenerationLimits.pack
        persistConsumable()
        print("[GenerationCredits] +\(Constants.GenerationLimits.pack) from tx=\(key), balance=\(consumableBalance)")
        return true
    }

    /// Prefer subscription allotment, then consumable pack.
    func consume(isSubscribed: Bool, isInIntroOffer: Bool) throws {
        if isSubscribed {
            if isInIntroOffer {
                if trialUsed < Constants.GenerationLimits.trial {
                    trialUsed += 1
                    persistTrial()
                    print("[GenerationCredits] trial used=\(trialUsed)/\(Constants.GenerationLimits.trial)")
                    return
                }
            } else if weeklyUsed < Constants.GenerationLimits.weekly {
                weeklyUsed += 1
                persistWeekly()
                print("[GenerationCredits] weekly used=\(weeklyUsed)/\(Constants.GenerationLimits.weekly)")
                return
            }
        }

        guard consumableBalance > 0 else {
            throw GenerationCreditError.noCredits
        }
        consumableBalance -= 1
        persistConsumable()
        print("[GenerationCredits] consumable balance=\(consumableBalance)")
    }

    func reset() {
        consumableBalance = 0
        trialUsed = 0
        weeklyUsed = 0
        trialOriginalID = nil
        weeklyPeriodID = nil
        UserDefaults.standard.removeObject(forKey: Constants.CreditsStorage.consumableBalanceKey)
        UserDefaults.standard.removeObject(forKey: Constants.CreditsStorage.trialUsedKey)
        UserDefaults.standard.removeObject(forKey: Constants.CreditsStorage.trialOriginalIDKey)
        UserDefaults.standard.removeObject(forKey: Constants.CreditsStorage.weeklyUsedKey)
        UserDefaults.standard.removeObject(forKey: Constants.CreditsStorage.weeklyPeriodKey)
        UserDefaults.standard.removeObject(forKey: Constants.CreditsStorage.processedConsumableIDsKey)
        print("[GenerationCredits] reset")
    }

    private func persistConsumable() {
        UserDefaults.standard.set(consumableBalance, forKey: Constants.CreditsStorage.consumableBalanceKey)
    }

    private func persistTrial() {
        UserDefaults.standard.set(trialUsed, forKey: Constants.CreditsStorage.trialUsedKey)
        if let trialOriginalID {
            UserDefaults.standard.set(trialOriginalID, forKey: Constants.CreditsStorage.trialOriginalIDKey)
        }
    }

    private func persistWeekly() {
        UserDefaults.standard.set(weeklyUsed, forKey: Constants.CreditsStorage.weeklyUsedKey)
        if let weeklyPeriodID {
            UserDefaults.standard.set(weeklyPeriodID, forKey: Constants.CreditsStorage.weeklyPeriodKey)
        }
    }
}
