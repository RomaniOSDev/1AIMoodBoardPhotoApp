//
//  OnboardingViewModel.swift
//  1AIMoodBoardPhotoApp
//

import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var hasCompletedOnboarding: Bool {
        userDefaults.bool(forKey: Constants.onboardingCompletedKey)
    }

    func completeOnboarding() {
        userDefaults.set(true, forKey: Constants.onboardingCompletedKey)
        print("[Onboarding] completed")
    }
}
