//
//  RootView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI
import SwiftData
import AppsFlyerLib

struct RootView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @State private var showOnboarding = false
    @State private var showPaywall = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label {
                        Text(L10n.Tab.home)
                    } icon: {
                        Image(systemName: "house.fill")
                    }
                }
                .tag(0)

            MyPhotosView()
                .tabItem {
                    Label {
                        Text(L10n.Tab.myPhotos)
                    } icon: {
                        Image(systemName: "photo.on.rectangle.angled")
                    }
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label {
                        Text(L10n.Tab.profile)
                    } icon: {
                        Image(systemName: "person.fill")
                    }
                }
                .tag(2)
        }
        .environment(\.mainTabSelection, $selectedTab)
        .onAppear {
            showOnboarding = !onboardingViewModel.hasCompletedOnboarding
            if !showOnboarding {
                presentPaywallIfNeeded()
                requestATTWhenMainUIVisible()
            }
        }
        .onChange(of: showOnboarding) { _, isShowing in
            if !isShowing {
                requestATTWhenMainUIVisible {
                    presentPaywallIfNeeded()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppEvents.showPaywall)) { _ in
            guard !showOnboarding else { return }
            showPaywall = true
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(viewModel: onboardingViewModel) {
                showOnboarding = false
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(
                storeKit: dependencies.storeKitManager,
                onSubscribed: {
                    showPaywall = false
                },
                onLimitedAccess: {
                    dependencies.freeTrialAccess.activate()
                    showPaywall = false
                }
            )
            .environmentObject(dependencies)
        }
    }

    private func presentPaywallIfNeeded() {
        guard !dependencies.storeKitManager.isSubscribed else { return }
        guard !dependencies.freeTrialAccess.isActive else { return }
        showPaywall = true
    }

    private func requestATTWhenMainUIVisible(afterATT: (() -> Void)? = nil) {
        AppTrackingCoordinator.requestAuthorizationIfNeeded(delay: 0.4) { _ in
            AppsFlyerLib.shared().start()
            afterATT?()
        }
    }
}

#Preview {
    let dependencies = AppDependencies()
    RootView()
        .environmentObject(dependencies)
        .modelContainer(dependencies.persistence.container)
}
