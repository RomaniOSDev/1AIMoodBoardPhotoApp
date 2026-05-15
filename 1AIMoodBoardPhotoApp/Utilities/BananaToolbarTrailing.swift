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
        HStack(spacing: 5) {
            Text("\(bananaManager.balance)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
            Image("bananmini")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

            Button {
                tabSelection.wrappedValue = MainTab.profileIndex
            } label: {
                Image(systemName: "plus.rectangle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Banana.toolbarBuyA11y)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
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
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.pinkApp.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                .shadow(color: Color.pinkApp.opacity(0.12), radius: 4, x: 0, y: 0)
        )
    }
}
