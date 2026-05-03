//
//  CustomButton.swift
//  1AIMoodBoardPhotoApp
//
//  Created by Roman on 4/30/26.
//

import SwiftUI

struct CustomButtonView: View {
    var image: String = ""
    var text: String = ""

    var body: some View {
        HStack(spacing: 8) {
            if !image.isEmpty {
                Image(systemName: image)
                    .font(.system(size: 17, weight: .semibold))
            }
            Text(text)
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .font(AppFont.custom(17, weight: .semibold))
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.pinkApp.opacity(0.95),
                            Color.pinkApp
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.26), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.pinkApp.opacity(0.55), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 4)
                .shadow(color: Color.pinkApp.opacity(0.2), radius: 5, x: 0, y: 0)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        
    }
}

#Preview {
    VStack(spacing: 14) {
        CustomButtonView(image: "plus", text: "Start Shoot")
        CustomButtonView(text: "Continue")
            .opacity(0.55)
    }
    .padding()
    .background(Color.backMain)
}
