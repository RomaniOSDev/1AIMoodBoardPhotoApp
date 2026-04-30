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
                    Text("Create your first AI photo shoot")
                        .font(.system(size: 24, weight: .light, design: .monospaced))
                    Text("Upload your mood board and get 20 lifestyle photos in minutes.")
                        .font(.system(size: 14, weight: .light, design: .default))
                        .opacity(0.4)
                }
                Button {
                    action()
                } label: {
                    CustomButtonView(text: "Start Shoot")
                }
            }
            .padding()
        }
    }
}

#Preview {
    NoShootView()
}
