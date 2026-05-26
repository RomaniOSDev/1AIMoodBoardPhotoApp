//
//  AppDependencies.swift
//  1AIMoodBoardPhotoApp
//

import SwiftData
import SwiftUI
import Combine

@MainActor
final class AppDependencies: ObservableObject {
    let persistence: PersistenceController
    let storeKitManager: StoreKitManager
    let freeTrialAccess: FreeTrialAccess
    let aiService: AIService

    private var cancellables = Set<AnyCancellable>()

    init() {
        persistence = PersistenceController.shared
        storeKitManager = StoreKitManager()
        freeTrialAccess = FreeTrialAccess.shared
        aiService = AIService(mode: Constants.aiUseLiveNetwork ? .live : .mock)

        storeKitManager.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        freeTrialAccess.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func repository(context: ModelContext) -> ShootRepository {
        ShootRepository(modelContext: context)
    }

    var canGeneratePhoto: Bool {
        storeKitManager.isSubscribed || freeTrialAccess.isActive
    }

    func reserveGeneration() throws {
        if storeKitManager.isSubscribed { return }
        if freeTrialAccess.isActive { return }
        throw FreeTrialError.notActive
    }

    func refundReservedGeneration() {}

    func confirmSuccessfulGeneration() {
        if storeKitManager.isSubscribed {
            print("[AppDependencies] premium generation")
        } else if freeTrialAccess.isActive {
            print("[AppDependencies] free trial generation")
        }
    }
}
