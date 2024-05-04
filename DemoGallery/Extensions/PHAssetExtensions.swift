//
//  PHAssetExtensions.swift
//  DemoGallery
//
//  Created by Chernyshov Artem Alekseevich on 21.04.2024.
//

import Photos
import UIKit

extension PHAsset {
    @discardableResult
    func requestImage(
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFit,
        resultHandler: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.isSynchronous = false

        self.caching(targetSize: targetSize, contentMode: contentMode, options: options)

        return PHCachingImageManager().requestImage(
            for: self,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options
        ) { image, _ in
            resultHandler(image)
        }
    }

    private func caching(targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions) {
        PHCachingImageManager().startCachingImages(
            for: [self],
            targetSize: targetSize,
            contentMode: contentMode,
            options: options
        )
    }
}
