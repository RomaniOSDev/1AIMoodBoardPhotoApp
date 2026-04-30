//
//  UIImage+Resize.swift
//  1AIMoodBoardPhotoApp
//

import UIKit

extension UIImage {
    /// Resizes so the longest side is at most `maxDimension`, preserving aspect ratio.
    func resized(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension, maxSide > 0 else { return self }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func jpegDataCompressed(quality: CGFloat) -> Data? {
        let scaled = resized(maxDimension: Constants.maxImageDimension)
        return scaled.jpegData(compressionQuality: quality)
    }
}
