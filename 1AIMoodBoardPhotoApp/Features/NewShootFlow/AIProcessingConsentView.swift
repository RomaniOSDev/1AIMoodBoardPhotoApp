//
//  AIProcessingConsentView.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI
import UIKit

struct AIProcessingConsentView: View {
    var onAgree: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(L10n.AIConsent.message)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.AIConsent.dataHeading)
                            .font(.subheadline.weight(.semibold))

                        consentBullet(L10n.AIConsent.dataSelfie)
                        consentBullet(L10n.AIConsent.dataStyle)
                        consentBullet(L10n.AIConsent.dataPrompt)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.AIConsent.recipientHeading)
                            .font(.subheadline.weight(.semibold))
                        Text(L10n.AIConsent.recipientBody)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Text(L10n.AIConsent.footer)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        openURL(AppLinks.privacyPolicy)
                    } label: {
                        Text(L10n.AIConsent.privacyLink)
                            .font(.footnote.weight(.semibold))
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .background(Color.backMain.ignoresSafeArea())
            .navigationTitle(L10n.AIConsent.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel, action: onCancel)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button(action: onAgree) {
                        Text(L10n.AIConsent.agree)
                            .font(AppFont.custom(17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .fill(Color.pinkApp)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
            }
        }
        .interactiveDismissDisabled()
    }

    private func consentBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(Color.pinkApp)
                .padding(.top, 7)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    AIProcessingConsentView(onAgree: {}, onCancel: {})
}
