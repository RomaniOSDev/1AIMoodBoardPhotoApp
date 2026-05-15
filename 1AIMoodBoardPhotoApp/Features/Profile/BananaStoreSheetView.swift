//
//  BananaStoreSheetView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI

struct BananaStoreSheetView: View {
    let dependencies: AppDependencies
    @ObservedObject var viewModel: ProfileViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BananaChaosBackground()
                    .allowsHitTesting(false)

                VStack(spacing: 18) {
                    Image(systemName: "lock.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.pinkApp)
                        .opacity(0.5)
                        
                    Text(L10n.Store.headline)
                        .font(AppFont.custom(24, weight: .bold))
                        .frame(maxWidth: 250)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                    Text(L10n.Store.subline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)

                    VStack(spacing: 12) {
                        ForEach(BananaPack.allCases) { pack in
                            Button {
                                Task {
                                    await viewModel.purchase(pack: pack, dependencies: dependencies)
                                }
                            } label: {
                                HStack {
                                    Text(pack.title)
                                        .font(.headline)
                                    Spacer()
                                    Text(dependencies.storeKitManager.displayPrice(for: pack))
                                        .font(AppFont.custom(24, weight: .heavy))
                                }
                                .padding()
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
                            .buttonStyle(.plain)
                            .disabled(dependencies.storeKitManager.purchaseInProgress)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(L10n.Store.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.pinkApp)
                            .opacity(0.6)
                    }

                   
                }
            }
        }
    }
}

private struct BananaChaosBackground: View {
    private struct BananaLayout: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let angle: Double
        let opacity: Double
    }

    // 10 bananas, each with different size/rotation/position.
    private let layouts: [BananaLayout] = [
        .init(id: 0, x: 0.10, y: 0.12, size: 34, angle: -24, opacity: 0.25),
        .init(id: 1, x: 0.23, y: 0.29, size: 58, angle: 18, opacity: 0.2),
        .init(id: 2, x: 0.84, y: 0.18, size: 42, angle: -12, opacity: 0.22),
        .init(id: 3, x: 0.71, y: 0.34, size: 66, angle: 29, opacity: 0.18),
        .init(id: 4, x: 0.15, y: 0.55, size: 50, angle: -31, opacity: 0.2),
        .init(id: 5, x: 0.39, y: 0.68, size: 38, angle: 24, opacity: 0.24),
        .init(id: 6, x: 0.82, y: 0.57, size: 52, angle: -20, opacity: 0.2),
        .init(id: 7, x: 0.58, y: 0.82, size: 72, angle: 13, opacity: 0.16),
        .init(id: 8, x: 0.09, y: 0.87, size: 44, angle: -9, opacity: 0.23),
        .init(id: 9, x: 0.89, y: 0.90, size: 36, angle: 34, opacity: 0.24)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(layouts) { item in
                    Image("oneBanan")
                        .resizable()
                        .scaledToFit()
                        .frame(width: item.size, height: item.size)
                        .rotationEffect(.degrees(item.angle))
                        .position(
                            x: geo.size.width * item.x,
                            y: geo.size.height * item.y
                        )
                }
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    BananaStoreSheetView(dependencies: AppDependencies(), viewModel: ProfileViewModel())
}
