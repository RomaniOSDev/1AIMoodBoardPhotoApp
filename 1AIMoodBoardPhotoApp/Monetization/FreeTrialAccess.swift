//
//  FreeTrialAccess.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import Combine

enum FreeTrialError: LocalizedError {
    case notActive

    var errorDescription: String? {
        switch self {
        case .notActive:
            return L10n.Paywall.freeTrialExpired
        }
    }
}

/// Limited tier: 3 calendar days of unlimited generations (starts when user chooses limited access on paywall).
@MainActor
final class FreeTrialAccess: ObservableObject {
    static let shared = FreeTrialAccess()

    @Published private(set) var trialEndDate: Date?

    private init() {
        if let interval = UserDefaults.standard.object(forKey: Constants.FreeTrial.endDateKey) as? TimeInterval {
            trialEndDate = Date(timeIntervalSince1970: interval)
        }
        purgeExpiredIfNeeded()
    }

    var isActive: Bool {
        guard let end = trialEndDate else { return false }
        return Date() < end
    }

    var hasAccess: Bool { isActive }

    /// Whole days left (at least 1 while trial is active).
    var daysRemaining: Int {
        guard let end = trialEndDate, isActive else { return 0 }
        let seconds = end.timeIntervalSinceNow
        return max(1, Int(ceil(seconds / 86_400)))
    }

    var hasUsedTrial: Bool {
        trialEndDate != nil
    }

    /// Starts a one-time 3-day unlimited trial (no-op if already active or already used).
    func activate() {
        if isActive { return }
        if hasUsedTrial { return }

        let end = Calendar.current.date(
            byAdding: .day,
            value: Constants.freeTrialDurationDays,
            to: Date()
        ) ?? Date().addingTimeInterval(86_400 * Double(Constants.freeTrialDurationDays))
        trialEndDate = end
        persist()
        print("[FreeTrialAccess] activated until \(end)")
    }

    func reset() {
        trialEndDate = nil
        UserDefaults.standard.removeObject(forKey: Constants.FreeTrial.endDateKey)
        print("[FreeTrialAccess] reset")
    }

    private func purgeExpiredIfNeeded() {
        guard let end = trialEndDate, Date() >= end else { return }
        objectWillChange.send()
    }

    private func persist() {
        if let end = trialEndDate {
            UserDefaults.standard.set(end.timeIntervalSince1970, forKey: Constants.FreeTrial.endDateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Constants.FreeTrial.endDateKey)
        }
    }
}
