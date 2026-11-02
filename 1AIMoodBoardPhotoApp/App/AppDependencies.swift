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
    let generationCredits: GenerationCredits
    let aiService: AIService

    private var cancellables = Set<AnyCancellable>()

    init() {
        persistence = PersistenceController.shared
        generationCredits = GenerationCredits.shared
        storeKitManager = StoreKitManager(credits: generationCredits)
        aiService = AIService(mode: Constants.aiUseLiveNetwork ? .live : .mock)

        storeKitManager.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        generationCredits.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func repository(context: ModelContext) -> ShootRepository {
        ShootRepository(modelContext: context)
    }

    var canGeneratePhoto: Bool {
        generationCredits.canGenerate(
            isSubscribed: storeKitManager.isSubscribed,
            isInIntroOffer: storeKitManager.isInIntroOfferPeriod
        )
    }

    var remainingGenerations: Int {
        generationCredits.remainingCredits(
            isSubscribed: storeKitManager.isSubscribed,
            isInIntroOffer: storeKitManager.isInIntroOfferPeriod
        )
    }

    func reserveGeneration() throws {
        // Soft check only — actual debit happens after a successful generation.
        guard canGeneratePhoto else {
            throw GenerationCreditError.noCredits
        }
    }

    func refundReservedGeneration() {}

    func confirmSuccessfulGeneration() {
        do {
            try generationCredits.consume(
                isSubscribed: storeKitManager.isSubscribed,
                isInIntroOffer: storeKitManager.isInIntroOfferPeriod
            )
            print("[AppDependencies] generation consumed, remaining=\(remainingGenerations)")
        } catch {
            print("[AppDependencies] consume failed: \(error)")
        }
    }
}
