//
//  PhotoAlbumSaver.swift
//  1AIMoodBoardPhotoApp
//

import UIKit

final class PhotoAlbumSaver: NSObject {
    private var completion: ((Error?) -> Void)?

    func saveToPhotoLibrary(_ image: UIImage) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            completion = { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        completion?(error)
        completion = nil
    }
}
