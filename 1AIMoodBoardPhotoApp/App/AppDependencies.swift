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
    let bananaManager: BananaManager
    let storeKitManager: StoreKitManager
    let aiService: AIService

    init() {
        persistence = PersistenceController.shared
        bananaManager = BananaManager.shared
        storeKitManager = StoreKitManager(bananaManager: bananaManager)
        aiService = AIService(mode: Constants.aiUseLiveNetwork ? .live : .mock)
    }

    func repository(context: ModelContext) -> ShootRepository {
        ShootRepository(modelContext: context)
    }
}
