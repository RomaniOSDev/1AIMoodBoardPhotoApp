//
//  MoodBoardApp.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI
import SwiftData
import UIKit

@main
struct MoodBoardApp: App {
    @StateObject private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies)
                .modelContainer(dependencies.persistence.container)
                .environment(\.font, AppFont.custom(17))
                .onAppear {
                    #if DEBUG
                    print("[AppFont] resolved=\(AppFont.resolvedName() ?? "nil")")
                    let playfairNames = UIFont.familyNames
                        .flatMap { UIFont.fontNames(forFamilyName: $0) }
                        .filter { $0.localizedCaseInsensitiveContains("playfair") }
                    print("[AppFont] available playfair names=\(playfairNames)")
                    #endif
                }
        }
    }
}
