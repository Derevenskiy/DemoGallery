//
//  LifeCameraCollectionViewCell.swift
//  DemoGallery
//
//  Created by Chernyshov Artem Alekseevich on 28.03.2024.
//

import UIKit
import SnapKit

class LifeCameraCollectionViewCell: UICollectionViewCell {

    private let cameraView = CameraView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addViews() {
        contentView.addSubview(cameraView)
        contentView.backgroundColor = .lightGray

        setupConstraints()
    }

    private func setupConstraints() {
        cameraView.snp.makeConstraints {
            $0.top.left.right.bottom.equalToSuperview()
        }
    }
}

struct LifeCameraCollectionViewCellModel {}
