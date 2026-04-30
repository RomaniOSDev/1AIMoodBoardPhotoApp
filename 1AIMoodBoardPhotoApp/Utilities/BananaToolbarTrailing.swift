//
//  BananaToolbarTrailing.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI

private enum MainTab {
    static let profileIndex = 2
}

private struct MainTabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    /// Selected index of root `TabView` (0 = Home, 1 = My Photos, 2 = Profile).
    var mainTabSelection: Binding<Int> {
        get { self[MainTabSelectionKey.self] }
        set { self[MainTabSelectionKey.self] = newValue }
    }
}

/// Right side of the navigation bar: asset banana icon, balance, plus (opens Profile to buy).
struct BananaToolbarTrailing: View {
    @ObservedObject private var bananaManager = BananaManager.shared
    @Environment(\.mainTabSelection) private var tabSelection

    var body: some View {
        HStack(spacing: 8) {
            Image("bananmini")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            Text("\(bananaManager.balance)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)

            Button {
                tabSelection.wrappedValue = MainTab.profileIndex
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Buy bananas")
        }
        .padding(.leading, 4)
    }
}
