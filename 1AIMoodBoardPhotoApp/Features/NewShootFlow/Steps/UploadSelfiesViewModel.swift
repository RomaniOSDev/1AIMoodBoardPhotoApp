//
//  UploadSelfiesViewModel.swift
//  1AIMoodBoardPhotoApp
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class UploadSelfiesViewModel: ObservableObject {
    @Published var images: [UIImage] = []
    @Published var showPicker = false

    private let maxPhotos = 1

    var hasPhoto: Bool { images.count == 1 }

    func addImages(_ new: [UIImage]) {
        guard !new.isEmpty else { return }
        var combined = images + new
        if combined.count > maxPhotos {
            // Keep the most recently picked images (replace flow: old + new → new wins).
            combined = Array(combined.suffix(maxPhotos))
        }
        images = combined
        print("[UploadSelfies] count=\(images.count)")
    }

    func removePhoto() {
        images = []
    }

    func replaceFlow() {
        showPicker = true
    }
}
