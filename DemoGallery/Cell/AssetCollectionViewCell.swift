//
//  AssetCollectionViewCell.swift
//  DemoGallery
//
//  Created by Chernyshov Artem Alekseevich on 17.03.2024.
//

import UIKit
import SnapKit

class AssetCollectionViewCell: UICollectionViewCell {
    
    private let asset = UIImageView()

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


    func configure(with image: UIImage?) {
        self.asset.image = image
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
