//
//  ImagePicker.swift
//  1AIMoodBoardPhotoApp
//

import PhotosUI
import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    var selectionLimit: Int
    var onComplete: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = selectionLimit
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else {
                parent.onComplete([])
                return
            }
            Task {
                var images: [UIImage] = []
                for result in results {
                    if let image = await loadImage(from: result) {
                        images.append(image)
                    }
                }
                await MainActor.run {
                    parent.onComplete(images)
                }
            }
        }

        private func loadImage(from result: PHPickerResult) async -> UIImage? {
            await withCheckedContinuation { continuation in
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let error {
                        print("[ImagePicker] load error: \(error)")
                    }
                    continuation.resume(returning: object as? UIImage)
                }
            }
        }
    }
}
