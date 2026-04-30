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
        var combined = images + new
        if combined.count > maxPhotos {
            combined = Array(combined.prefix(maxPhotos))
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
