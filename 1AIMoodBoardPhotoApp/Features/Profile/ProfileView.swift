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
    @ObservedObject private var bananaManager = BananaManager.shared

    @StateObject private var viewModel = ProfileViewModel()
    @State private var libraryPhotoCount = 0
    @State private var showBananaStore = false
    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            Color.backMain.ignoresSafeArea()

            
                ScrollView {
                    VStack(spacing: 14) {
                    HStack {
                        Text("Profile")
                            .font(AppFont.custom(32, weight: .bold))

                        Spacer()

                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.pinkApp)
                            .opacity(0.7)
                    }

                        ProfileCard(title: "Bananas") {
                            HStack {
                                Text("Balance")
                                Spacer()
                                Image("bananmini")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("\(bananaManager.balance)")
                                    .font(.title2.bold())
                            }
                            .padding(.bottom, 6)

                            Button {
                                showBananaStore = true
                            } label: {
                                ProfileActionButtonLabel(
                                    title: "Buy bananas",
                                    icon: "cart.fill"
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                Task { await viewModel.restore(dependencies: dependencies) }
                            } label: {
                                ProfileActionButtonLabel(
                                    title: "Restore Purchases",
                                    icon: "arrow.clockwise"
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(dependencies.storeKitManager.purchaseInProgress)

                            if let loadError = dependencies.storeKitManager.loadErrorMessage {
                                Text(loadError)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)

                                Button {
                                    Task { await dependencies.storeKitManager.loadProducts() }
                                } label: {
                                    ProfileActionButtonLabel(
                                        title: "Reload products",
                                        icon: "arrow.triangle.2.circlepath"
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(dependencies.storeKitManager.purchaseInProgress)
                            }
                        }

                        ProfileCard(title: "Activity") {
                            HStack {
                                Text("Generations in library")
                                Spacer()
                                Text("\(libraryPhotoCount)")
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("Bananas spent (lifetime)")
                                Spacer()
                                Text("\(bananaManager.totalBananasSpentStatistic)")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        ProfileCard(title: "Support") {
                            Button {
                                rateApp()
                            } label: {
                                ProfileActionButtonLabel(title: "Rate Us", icon: "star.fill")
                            }
                            .buttonStyle(.plain)

                            Button {
                                openURL(AppLinks.privacyPolicy)
                            } label: {
                                ProfileActionButtonLabel(title: "Privacy", icon: "lock.fill")
                            }
                            .buttonStyle(.plain)

                            Button {
                                openURL(AppLinks.termsOfUse)
                            } label: {
                                ProfileActionButtonLabel(title: "Terms", icon: "doc.text.fill")
                            }
                            .buttonStyle(.plain)
                        }

                        ProfileCard(title: "Danger Zone") {
                            Button(role: .destructive) {
                                showResetConfirmation = true
                            } label: {
                                ProfileActionButtonLabel(
                                    title: "Reset all data",
                                    icon: "trash.fill",
                                    destructive: true
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                        }
                    }
                    .padding()
                }
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
                .alert("Reset Data", isPresented: $viewModel.showResetAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.resetMessage)
                }
                .confirmationDialog(
                    "This will remove all generated photos, sessions, and reset your balance/stats.",
                    isPresented: $showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset all data", role: .destructive) {
                        Task {
                            let didReset = await viewModel.resetAllData(
                                dependencies: dependencies,
                                modelContext: modelContext
                            )
                            if didReset {
                                libraryPhotoCount = 0
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
                .sheet(isPresented: $showBananaStore) {
                    BananaStoreSheetView(dependencies: dependencies, viewModel: viewModel)
                        .presentationDetents([.fraction(0.75), .large])
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("openBananaStore"))) { _ in
                    showBananaStore = true
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

private struct ProfileCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                Text(title)
                                    .font(AppFont.custom(24, weight: .heavy))
                                Spacer()
                            }
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemBackground),
                            Color(.secondarySystemBackground).opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.pinkApp.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .shadow(color: Color.pinkApp.opacity(0.1), radius: 4, x: 0, y: 0)
        )
    }
}

private struct ProfileActionButtonLabel: View {
    let title: String
    let icon: String
    var destructive: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .foregroundStyle(destructive ? .red : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(destructive ? Color.red.opacity(0.08) : Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            destructive ? Color.red.opacity(0.35) : Color.white.opacity(0.18),
                            lineWidth: 1
                        )
                )
        )
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


