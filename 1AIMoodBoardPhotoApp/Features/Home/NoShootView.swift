//
//  NoShootView.swift
//  1AIMoodBoardPhotoApp
//
//  Created by Roman on 4/30/26.
//

import SwiftUI

struct NoShootView: View {
    var action: () -> Void = { }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.pinkApp)
                .opacity(0.1)
            VStack(spacing: 20){
                HStack{
                    Image(.pre1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Image(.after1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.top, 40)
                    Spacer()
                }
                VStack(alignment: .leading,spacing: 15) {
                    Text(L10n.Home.emptyCreateFirst)
                        .font(.system(size: 24, weight: .light, design: .monospaced))
                    Text(L10n.Home.emptySubtitle)
                        .font(.system(size: 14, weight: .light, design: .default))
                        .opacity(0.4)
                }
                Button {
                    action()
                } label: {
                    CustomButtonView(text: L10n.Home.emptyStartShot)
                }
            }
            .padding()
        }
    }
}

#Preview {
    NoShootView()
}
