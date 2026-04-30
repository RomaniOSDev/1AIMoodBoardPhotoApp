//
//  StyleSelectionView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI
import UIKit

struct StyleSelectionView: View {
    @ObservedObject var coordinator: NewShootCoordinator

    @State private var selectedPreset: VibePreset?
    @State private var referenceImage: UIImage?
    @State private var showPicker = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var canContinue: Bool {
        selectedPreset != nil || referenceImage != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose style direction")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 10) {
                    Text("Reference photo (optional)")
                        .font(.headline)

                    Button {
                        showPicker = true
                    } label: {
                        if let referenceImage {
                            Image(uiImage: referenceImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            VStack(spacing: 10) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2)
                                Text("Attach reference")
                                    .font(.subheadline.weight(.medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    .foregroundStyle(Color.secondary.opacity(0.5))
                            )
                        }
                    }
                    .buttonStyle(.plain)

                    if referenceImage != nil {
                        Button("Remove reference") {
                            referenceImage = nil
                        }
                        .font(.subheadline.weight(.medium))
                    }
                }

                Text("Or choose a preset")
                    .font(.headline)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(VibePreset.allCases) { preset in
                        Button {
                            selectedPreset = preset
                        } label: {
                            VStack(spacing: 10) {
                                Group {
                                    if let preview = UIImage(named: preset.previewAssetName) {
                                        Image(uiImage: preview)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Image(systemName: preset.symbolName)
                                            .font(.system(size: 26))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(height: 90)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.secondarySystemBackground))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                Text(preset.rawValue)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedPreset == preset ? Color.accentColor.opacity(0.18) : Color(.systemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(selectedPreset == preset ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Step 2 of 3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                coordinator.selectedVibe = selectedPreset
                coordinator.referenceStyleImage = referenceImage
                coordinator.push(.processing)
            } label: {
                CustomButtonView(text: "Continue")
            }
            .buttonStyle(.plain)
            .disabled(!canContinue)
            .padding()
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(selectionLimit: 1) { picked in
                referenceImage = picked.first
            }
        }
        .onAppear {
            selectedPreset = coordinator.selectedVibe
            referenceImage = coordinator.referenceStyleImage
        }
    }
}
