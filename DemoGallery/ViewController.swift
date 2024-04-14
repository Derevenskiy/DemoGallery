//
//  ViewController.swift
//  DemoGallery
//
//  Created by Chernyshov Artem Alekseevich on 02.03.2024.
//

import UIKit
import SnapKit
import Photos
import PhotosUI

enum MediaType {
    case lifeCamera
    case camera
    case photos
    case videos
    case all
}

class ViewController: UIViewController {
    private var assets: [Any] = []

    private var assetsFetchResult = PHFetchResult<PHAsset>() {
        didSet {
            var newAsset: [PHAsset] = []
            assetsFetchResult.enumerateObjects { asset, _, _ in
                newAsset.append(asset)
            }
            assets = newAsset
        }
    }

    private var fetchLimit = 20
    private var mediaType: MediaType = .photos {
        didSet {
            if mediaType == .lifeCamera {
                guard let assetsLifeCamera = assets as? [LifeCameraCollectionViewCellModel],
                      assetsLifeCamera.count < 1 else { return }

                assets.append(LifeCameraCollectionViewCellModel())

                DispatchQueue.main.async { [weak self] in
                    self?.collectionView.reloadData()
                }
            }
        }
    }

    private let buttonsView = ButtonsView()

    private lazy var assetsSegmentedControl: UISegmentedControl = {
        let assetsSwitch = UISegmentedControl(items: ["lifeCamera", "camera", "photos", "videos", "all"])
        assetsSwitch.selectedSegmentIndex = 2
        assetsSwitch.addTarget(self, action: #selector(segmentedValueChanged), for: .valueChanged)
        return assetsSwitch
    }()

    private lazy var accessImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var goToSettingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("go to settings", for: .normal)
        button.addTarget(self, action: #selector(goToSettings), for: .touchUpInside)
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(AssetCollectionViewCell.self, forCellWithReuseIdentifier: "AssetCollectionViewCell")
        collectionView.register(LifeCameraCollectionViewCell.self, forCellWithReuseIdentifier: "LifeCameraCollectionViewCell")
        collectionView.delegate = self
        collectionView.dataSource = self

        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()

        Task {
            let status = await checkAuthorizationStatus()

            switch status {
            case .limited:
                accessImageView.isHidden = false
                goToSettingsButton.isHidden = false
                accessImageView.image = UIImage(named: "accessIsLimited")
                buttonsView.isUserInteractionEnabled = true
            case .restricted, .denied:
                accessImageView.isHidden = false
                goToSettingsButton.isHidden = false
                accessImageView.image = UIImage(named: "accessDenied")
                buttonsView.isUserInteractionEnabled = false
            default:
                accessImageView.isHidden = true
                goToSettingsButton.isHidden = true
                accessImageView.image = nil
                buttonsView.isUserInteractionEnabled = true
            }
        }

    }

    private func setupUI() {
        buttonsView.delegate = self

        PHPhotoLibrary.shared().register(self)

        view.addSubviews([
            buttonsView,
            assetsSegmentedControl,
            collectionView,
            accessImageView,
            goToSettingsButton
        ])
    }

    private func setupConstraints() {
        buttonsView.snp.makeConstraints {
            $0.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(16)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(60)
        }

        assetsSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(buttonsView.snp.bottom).offset(20)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }


        collectionView.snp.makeConstraints {
            $0.top.equalTo(assetsSegmentedControl.snp.bottom).offset(20)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        accessImageView.snp.makeConstraints {
            $0.center.equalTo(self.view.snp.center)
            $0.width.equalTo(self.view.frame.width)
            $0.height.equalTo(self.view.frame.width)
        }

        goToSettingsButton.snp.makeConstraints {
            $0.top.equalTo(accessImageView.snp.bottom)
            $0.centerX.equalTo(self.view.snp.centerX)
            $0.width.equalTo(view.bounds.width / 2)
            $0.height.equalTo(44)
        }
    }

    @objc
    private func segmentedValueChanged(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mediaType = .lifeCamera
        case 1:
            mediaType = .camera
        case 2:
            mediaType = .photos
        case 3:
            mediaType = .videos
        case 4:
            mediaType = .all

        default: break
        }
    }

    @objc
    private func openGallery() {
        Task {
            let status = await checkAuthorizationStatus()
            if status == .limited {
                await PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
            } else {
                if mediaType == .camera {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = .camera
                    present(imagePicker, animated: true, completion: nil)
                } else {
                    let photoLibrary = PHPhotoLibrary.shared()
                    var config = PHPickerConfiguration(photoLibrary: photoLibrary)
                    config.selectionLimit = 3
                    config.filter = pickMedia()

                    let imagePicker = PHPickerViewController(configuration: config)
                    imagePicker.delegate = self
                    present(imagePicker, animated: true, completion: nil)
                }
            }
        }
    }

    private func pickMedia() -> PHPickerFilter? {
        if mediaType == .photos {
            return .images
        } else if mediaType == .videos {
            return .videos
        } else {
            return nil
        }
    }

    @objc
    private func getAllAsset(with fetchLimit: Int = 20) {
        var assetsFetchResult = PHFetchResult<PHAsset>()

        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotosOptions.fetchLimit = assets.count + fetchLimit

        assetsFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: allPhotosOptions)
        self.assetsFetchResult = assetsFetchResult

        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reloadData()
        }
    }

    @objc
    private func clearAllAsset() {
        assets.removeAll()
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reloadData()
        }
    }

    @objc
    private func goToSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    private func checkAuthorizationStatus() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
}

// MARK: - UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        assets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = assets[indexPath.row]

        if let asset = asset as? PHAsset {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "AssetCollectionViewCell",
                for: indexPath
            ) as? AssetCollectionViewCell else { fatalError("AssetCollectionViewCell is not found") }

            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = false

            manager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image,_ in
                guard let image = image else { return }

                DispatchQueue.main.async {
                    cell.configure(with: image)
                }
            }
            return cell
        } else if assets[indexPath.row] is LifeCameraCollectionViewCellModel {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "LifeCameraCollectionViewCell",
                for: indexPath
            ) as? LifeCameraCollectionViewCell else { fatalError("LifeCameraCollectionViewCell is not found") }

            return cell
        } else {
            fatalError("asset is not")
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let asset = assets[indexPath.row]

        if asset is PHAsset {
            let size = (self.view.frame.width / 3) - 5
            return .init(width: size, height: size)
        } else if asset is LifeCameraCollectionViewCellModel {
            let height = collectionView.bounds.height / 2
            return .init(width: collectionView.bounds.width, height: height)
        } else {
            fatalError("asset is not")
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
            assets.append(asset)

            DispatchQueue.main.async { [weak self] in
                self?.collectionView.reloadData()
            }
        } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { [weak self] succes, _ in
                guard let self = self, succes else { return }
                getAllAsset(with: 1)
            })
        }

        picker.dismiss(animated: true)
    }
}


// MARK: - PHPickerViewControllerDelegate

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        let identifiers = results.compactMap(\.assetIdentifier)
        assetsFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reloadData()
        }

    }
}

// MARK: - UICollectionViewDelegate

extension ViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let contentOffsetX = scrollView.contentOffset.y
        if contentOffsetX >= (scrollView.contentSize.height - scrollView.bounds.height) {
            getAllAsset()
        }
    }
}

// MARK: - ButtonsViewDelegate

extension ViewController: ButtonsViewDelegate {
    func buttonDidTap(with type: ButtonType) {
        switch type {
        case .gallery:
            openGallery()
        case .asset:
            getAllAsset()
        case .clearAsset:
            clearAllAsset()
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension ViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let changes = changeInstance.changeDetails(for: assetsFetchResult) {
                assetsFetchResult = changes.fetchResultAfterChanges
                if changes.hasIncrementalChanges {
                    collectionView.performBatchUpdates({ [weak self] in
                        guard let self = self else { return }

                        if let removed = changes.removedIndexes, removed.count > 0 {
                            collectionView.deleteItems(at: removed.map { IndexPath(item: $0, section:0) })
                        }
                        if let inserted = changes.insertedIndexes, inserted.count > 0 {
                            collectionView.insertItems(at: inserted.map { IndexPath(item: $0, section:0) })
                        }
                        if let changed = changes.changedIndexes, changed.count > 0 {
                            collectionView.reloadItems(at: changed.map { IndexPath(item: $0, section:0) })
                        }
                        changes.enumerateMoves { [weak self] fromIndex, toIndex in
                            guard let self = self else { return }
                            collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                    to: IndexPath(item: toIndex, section: 0))
                        }
                    })
                } else {
                    collectionView.reloadData()
                }
            }
        }
    }
}
