//
//  AssetCollectionViewCell.swift
//  DemoGallery
//
//  Created by Chernyshov Artem Alekseevich on 17.03.2024.
//

import UIKit
import SnapKit
import Photos

enum PHImageManagerType {
    case imageManager
    case cachingImageManager
}

class AssetCollectionViewCell: UICollectionViewCell {
    private let asset = UIImageView()

    private let imageManagerType: PHImageManagerType = .cachingImageManager

    override init(frame: CGRect) {
        super.init(frame: frame)

        addViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        asset.image = nil
    }


    func configure(with asset: PHAsset) {
        //PHImageManagerMaximumSize - если ставить его, то ячейки при быстром скролле могут наполниться не тем контентом, при более низком разрешении все ок работает
        let targetSize: CGSize = .init(width: bounds.width * 2, height: bounds.height * 2)

        if imageManagerType == .imageManager {
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: nil
            ) { image,_ in
                guard let image = image else { return }

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.asset.image = image
                }
            }
        } else {
            asset.requestImage(
                targetSize: targetSize,
                resultHandler: { image in
                    guard let image = image else { return }

                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.asset.image = image
                    }
                }
            )
        }
    }

    private func addViews() {
        contentView.addSubview(asset)
        contentView.backgroundColor = .lightGray
        asset.contentMode = .scaleAspectFit

        setupConstraints()
    }

    private func setupConstraints() {
        asset.snp.makeConstraints {
            $0.top.left.right.bottom.equalToSuperview()
        }
    }
}
