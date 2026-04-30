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
        ZStack{
            RoundedRectangle(cornerRadius: 15)
                .foregroundStyle(.pinkApp)
                .shadow(radius: 5)
            HStack{
                if !image.isEmpty {
                    Image(systemName: image)
                }
                Text(text)
            }
            .foregroundStyle(.white)
            .font(.system(size: 18, weight: .regular, design: .monospaced))
            .padding()
        }
        .frame(height: 55)
        
    }
}

#Preview {
    CustomButtonView(image: "plus", text: "Start Shoot")
}
