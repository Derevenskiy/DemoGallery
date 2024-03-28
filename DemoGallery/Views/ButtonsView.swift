//
//  ButtonsView.swift
//  DemoGallery
//
//  Created by Chernyshov Artem Alekseevich on 23.03.2024.
//

import UIKit
import SnapKit

enum ButtonType {
    case gallery
    case asset
    case clearAsset
}

protocol ButtonsViewDelegate: AnyObject {
    func buttonDidTap(with type: ButtonType)
}

final class ButtonsView: UIView {

    weak var delegate: ButtonsViewDelegate?

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()

    private lazy var buttonGalleryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Open Gallery", for: .normal)
        button.backgroundColor = .systemGreen
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }()

    private lazy var allAssetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Get all asset", for: .normal)
        button.backgroundColor = .systemGray
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }()

    private lazy var clearAssetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear all asset", for: .normal)
        button.backgroundColor = .systemRed
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }()

    init() {
        super.init(frame: .zero)
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    @objc
    private func didTapButton(with sender: UIButton) {
        if sender == buttonGalleryButton {
            delegate?.buttonDidTap(with: .gallery)
        } else if sender == allAssetButton {
            delegate?.buttonDidTap(with: .asset)
        } else if sender == clearAssetButton {
            delegate?.buttonDidTap(with: .clearAsset)
        }
    }

    private func setupView() {
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.masksToBounds = true

        addSubview(stackView)
        stackView.addArrangedSubview(buttonGalleryButton)
        stackView.addArrangedSubview(allAssetButton)
        stackView.addArrangedSubview(clearAssetButton)
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints {
            $0.top.left.right.bottom.equalToSuperview()
        }
    }
}
