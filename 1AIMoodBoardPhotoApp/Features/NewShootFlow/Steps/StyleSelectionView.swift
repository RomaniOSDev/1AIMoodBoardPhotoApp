//
//  StyleSelectionView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI

struct StyleSelectionView: View {
    @ObservedObject var coordinator: NewShootCoordinator

    @State private var selectedPreset: VibePreset?
    @State private var customPrompt = ""

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var canContinue: Bool {
        selectedPreset != nil || !customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose style direction")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 10) {
                    Text("Describe your custom edit")
                        .font(.headline)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                            )

                        TextEditor(text: $customPrompt)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 8)

                        if customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Describe how you want your selfie to change — lighting, outfit vibe, background, mood…")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }

                    Text("Example: Keep my face and hair the same, add a soft cinematic evening mood with warm lights.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                coordinator.customPrompt = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                coordinator.push(.processing)
            } label: {
                CustomButtonView(text: "Continue")
            }
            .buttonStyle(.plain)
            .disabled(!canContinue)
            .padding()
            .background(.ultraThinMaterial)
        }
        .onAppear {
            selectedPreset = coordinator.selectedVibe
            customPrompt = coordinator.customPrompt
        }
    }
}
