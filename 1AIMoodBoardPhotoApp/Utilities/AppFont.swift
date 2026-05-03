//
//  AppFont.swift
//  1AIMoodBoardPhotoApp
//

import SwiftUI
import UIKit
import CoreText

enum AppFont {
    private static let preferredFileNames = [
        "PlayfairDisplay-Italic.ttf",
        "PlayfairDisplay.ttf"
    ]
    private static var cachedResolvedName: String?
    private static var didAttemptRegistration = false

    static func custom(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let name = resolvedName(), UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight)
    }

    static func resolvedName() -> String? {
        if let cachedResolvedName {
            return cachedResolvedName
        }
        if !didAttemptRegistration {
            registerPlayfairFontsIfNeeded()
            didAttemptRegistration = true
        }

        // Prefer italic face if available.
        let allNames = UIFont.familyNames
            .flatMap { UIFont.fontNames(forFamilyName: $0) }
            .filter { $0.localizedCaseInsensitiveContains("playfair") }

        if let italic = allNames.first(where: { $0.localizedCaseInsensitiveContains("italic") }) {
            cachedResolvedName = italic
            return italic
        }
        if let first = allNames.first {
            cachedResolvedName = first
            return first
        }
        return nil
    }

    private static func registerPlayfairFontsIfNeeded() {
        for fileName in preferredFileNames {
            guard let fontURL = fontURL(for: fileName) else { continue }
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }

    private static func fontURL(for fileName: String) -> URL? {
        let ns = fileName as NSString
        let base = ns.deletingPathExtension
        let ext = ns.pathExtension
        if let inSubdir = Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "Utilities/Fonts") {
            return inSubdir
        }
        return Bundle.main.url(forResource: base, withExtension: ext)
    }
}
