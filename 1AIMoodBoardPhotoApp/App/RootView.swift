//
//  RootView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI
import SwiftData

struct RootView: View {
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @State private var showOnboarding = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            MyPhotosView()
                .tabItem {
                    Label("My Photos", systemImage: "photo.on.rectangle.angled")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .environment(\.mainTabSelection, $selectedTab)
        .onAppear {
            showOnboarding = !onboardingViewModel.hasCompletedOnboarding
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(viewModel: onboardingViewModel) {
                showOnboarding = false
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies()
    return RootView()
        .environmentObject(dependencies)
        .modelContainer(dependencies.persistence.container)
}
