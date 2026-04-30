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
            VStack(alignment: .leading, spacing: 18) {
                Text("Bananas - your currency for images")
                    .font(.title3.bold())
                Text("1 banana = 1 image\nCreate images in seconds")
                    .foregroundStyle(.secondary)

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
                                    .font(.headline.weight(.semibold))
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(dependencies.storeKitManager.purchaseInProgress)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Buy Bananas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
