//
//  ProfileView.swift
//  1AIMoodBoardPhotoApp
//

import StoreKit
import SwiftData
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = ProfileViewModel()
    @State private var libraryPhotoCount = 0

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Profile")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))

                    Spacer()

                    BananaToolbarTrailing()
                }

                List {
                    Section("Bananas") {
                        HStack {
                            Text("Balance")
                            Spacer()
                            Text("\(dependencies.bananaManager.balance)")
                                .font(.title2.bold())
                        }

                        Button {
                            Task { await viewModel.purchase(dependencies: dependencies) }
                        } label: {
                            Text("Buy 10 bananas – \(formattedPrice)")
                        }
                        .disabled(dependencies.storeKitManager.purchaseInProgress)

                        Button("Restore Purchases") {
                            Task { await viewModel.restore(dependencies: dependencies) }
                        }
                        .disabled(dependencies.storeKitManager.purchaseInProgress)

                        if dependencies.storeKitManager.products.isEmpty {
                            Text("StoreKit products are not loaded. Attach `Configuration.storekit` in Scheme -> Run -> Options.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button("Reload products") {
                                Task { await dependencies.storeKitManager.loadProducts() }
                            }
                            .disabled(dependencies.storeKitManager.purchaseInProgress)
                        }
                    }

                    Section("Activity") {
                        HStack {
                            Text("Generations in library")
                            Spacer()
                            Text("\(libraryPhotoCount)")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Bananas spent (lifetime)")
                            Spacer()
                            Text("\(dependencies.bananaManager.totalBananasSpentStatistic)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(viewModel.appVersion)
                                .foregroundStyle(.secondary)
                                .font(.caption.monospaced())
                        }
                    }

                    Section("Developer") {
                        Text("Set `Constants.aiUseLiveNetwork = true` in `Constants.swift`, add your WaveSpeed API key, then rebuild.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        #if DEBUG
                        Button("Add 10 test bananas") {
                            dependencies.bananaManager.addPurchasedBananas(10)
                        }
                        #endif
                    }
                }
            }
            .padding()
            .onAppear {
                libraryPhotoCount = viewModel.generationCount(repository: dependencies.repository(context: modelContext))
            }
            .alert("Purchase", isPresented: $viewModel.showPurchaseError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.purchaseErrorMessage)
            }
            .alert("Restore", isPresented: $viewModel.showRestoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.restoreMessage)
            }
        }
    }

    private var formattedPrice: String {
        if let product = dependencies.storeKitManager.products.first(where: { $0.id == Constants.bananaProductID }) {
            return product.displayPrice
        }
        return "$4.99"
    }
}
