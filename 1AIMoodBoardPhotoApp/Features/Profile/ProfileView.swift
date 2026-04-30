//
//  ProfileView.swift
//  1AIMoodBoardPhotoApp
//

import StoreKit
import SwiftData
import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = ProfileViewModel()
    @State private var libraryPhotoCount = 0
    @State private var showBananaStore = false

    var body: some View {
        ZStack{
            Color.backMain.ignoresSafeArea()
            
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
                            
                            Button("Buy bananas") {
                                showBananaStore = true
                            }
                            
                            
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

                        Section("Support") {
                            Button("Rate Us") {
                                rateApp()
                            }
                            Button("Privacy") {
                                openURL(AppLinks.privacyPolicy)
                            }
                            Button("Terms") {
                                openURL(AppLinks.termsOfUse)
                            }
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
                .sheet(isPresented: $showBananaStore) {
                    BananaStoreSheetView(dependencies: dependencies, viewModel: viewModel)
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }

    private func openURL(_ value: String) {
        if let url = URL(string: value) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

private struct ProfilePreviewHost: View {
    let dependencies = AppDependencies()

    var body: some View {
        ProfileView()
            .environmentObject(dependencies)
            .modelContainer(dependencies.persistence.container)
    }
}

#Preview {
    ProfilePreviewHost()
}


