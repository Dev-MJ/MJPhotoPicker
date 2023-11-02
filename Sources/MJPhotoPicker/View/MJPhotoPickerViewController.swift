//
//  MJPhotoPickerViewController.swift
//  MJPhotoPicker
//
//  Created by mj.lee on 2023/11/02.
//

import UIKit
import Combine
import Photos

@objcMembers
public final class MJPhotoPickerViewController: UIViewController {
    private let backView: UIView = {
       let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let fakeNavigationBar: FakeNavigationBar = {
        let f = FakeNavigationBar()
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()
    private let collectionViewLayout: UICollectionViewCompositionalLayout = {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3),
                                                   heightDimension: .fractionalWidth(1/3))
        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
        layoutItem.contentInsets = .init(top: 0, leading: 0, bottom: 1.5, trailing: 1.5)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .fractionalWidth(1/3))
        let layoutGroup = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [layoutItem])
        
        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
       return UICollectionViewCompositionalLayout(section: layoutSection)
    }()
    internal lazy var collectionView: UICollectionView = {
        let v = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.allowsMultipleSelection = true
        v.allowsSelection = true
        return v
    }()

    private weak var childViewController: AssetAlbumListViewController?
    private var viewModel: PhotoPickerViewModel!// = .init()
    private var subscriptions: Set<AnyCancellable> = .init()
    
    public var assetDidTapPublisher: PassthroughSubject<PhotoPickerWrapperAsset, Never> = .init()
    public var selectedAssetsPublisher: PassthroughSubject<[PhotoPickerWrapperAsset], Never> = .init()
    public var exitPublisher: PassthroughSubject<(), Never> = .init()

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        debugPrint("MJPhotoPickerViewController deinit")
    }

    public convenience init(configuration: PickerConfiguration) {
        configuration.updateSupply()
        self.init()
        self.viewModel = .init(configuration: configuration)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addSubviews()
        self.configureConstraints()
        
        self.requestPHPhotoLibraryAuthorization {
            Task { @MainActor in
                self.configureCollectionView()
                self.bindViewModel()
                self.bindView()
                self.implementDragSelectable()
                PHPhotoLibrary.shared().register(self)
            }
        }
    }
    
    private func requestPHPhotoLibraryAuthorization(completion: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { (status) in
            switch status {
            case .limited:
                completion()
            case .authorized:
                completion()
            default:
                self.dismiss(animated: true)
            }
        }
    }
    
    private func addSubviews() {
        view.addSubview(self.backView)
        self.backView.addSubview(self.collectionView)
        self.backView.addSubview(self.fakeNavigationBar)
    }
    
    private func configureCollectionView() {
        self.collectionView.register(PickerThumbnailCell.self,
                                     forCellWithReuseIdentifier: "PickerThumbnailCell")
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.prefetchDataSource = self
    }
    
    private func bindViewModel() {
        self.viewModel.$selectedAssets
            .map { $0.map { .init(asset: $0) }}
            .receive(on: DispatchQueue.main)
            .subscribe(selectedAssetsPublisher)
            .store(in: &subscriptions)
        
        self.viewModel.changedSelectionItemsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] willBeSelected, indexPath in
                if willBeSelected {
                    self?.collectionView.selectItem(at: indexPath,
                                                    animated: true,
                                                    scrollPosition: .centeredHorizontally)
                } else {
                    self?.collectionView.deselectItem(at: indexPath, animated: true)
                }
            }.store(in: &subscriptions)
        
        self.viewModel.reloadDataPublisher
            .sink { [weak self] animated in
                self?.reloadData(animated: animated)
            }.store(in: &subscriptions)
    }
    public var selectedAlbumWillChangePublisher: PassthroughSubject<String, Never> = .init()
    private func bindViewController() {
        let publisher = self.childViewController?.selectedAlbumWillChangePublisher
            .multicast(subject: PassthroughSubject<(title: String, type: AssetAlbumListCellModel.`Type`), Never>())
        
        publisher?
            .map { $0.title }
            .subscribe(selectedAlbumWillChangePublisher)
            .store(in: &subscriptions)

        publisher?
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self else { return }
                if self.viewModel.assets.count > 0 {
                    self.collectionView.scrollToItem(at: .init(item: 0, section: 0),
                                                      at: .top,
                                                      animated: false)
                }
            })
            .sink { [weak self] (title, type) in
                guard let self else { return }
                DispatchQueue.main.async {
                    switch type {
                    case .collection(let collection):
                        self.viewModel.fetch(from: collection)
                    case .custom(let assets):
                        self.viewModel.fetch(from: assets)
                    }
                    self.fakeNavigationBar.setTitle(title)
                }
                
            }.store(in: &subscriptions)
        
        publisher?.connect()
            .store(in: &subscriptions)
    }
    
    private func bindView() {
        self.fakeNavigationBar.closeTapPublisher
            .subscribe(exitPublisher)
            .store(in: &subscriptions)
        
        self.fakeNavigationBar.titleTapPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                guard self.children.isEmpty else {
                    self.removeAssetAlbumListViewController()
                    return
                }
                self.addAssetAlbumListViewController()
                self.bindViewController()
            }.store(in: &subscriptions)
    }
    
    private func addAssetAlbumListViewController() {
        let childVC = AssetAlbumListViewController()
        self.present(childVC, animated: true)
        self.childViewController = childVC
    }
    
    private func removeAssetAlbumListViewController() {
        guard let childVC = self.childViewController else { return }
        childVC.dismiss(animated: true)
        self.childViewController = nil
    }
    
    private func configureConstraints() {
        NSLayoutConstraint.activate([
            self.backView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            self.backView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.backView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.backView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            
            self.fakeNavigationBar.widthAnchor.constraint(equalTo: self.backView.widthAnchor),
            self.fakeNavigationBar.heightAnchor.constraint(equalToConstant: 54),
            self.fakeNavigationBar.leadingAnchor.constraint(equalTo: self.backView.leadingAnchor),
            self.fakeNavigationBar.topAnchor.constraint(equalTo: self.backView.topAnchor),
            
            self.collectionView.widthAnchor.constraint(equalTo: self.backView.widthAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.backView.bottomAnchor),
            self.collectionView.leadingAnchor.constraint(equalTo: self.backView.leadingAnchor),
            self.collectionView.topAnchor.constraint(equalTo: self.fakeNavigationBar.bottomAnchor),
        ])
    }
    
    private func reloadData(animated: Bool) {
        self.collectionViewLayout.invalidateLayout()
        if animated {
            UIView.transition(with: self.collectionView,
                              duration: 0.25,
                              options: .transitionCrossDissolve) {
                self.collectionView.reloadData()
            }
        } else {
            self.collectionView.reloadData()
        }
    }
    
    public func check(asset: PhotoPickerWrapperAsset) {
        let indexPath = self.viewModel.indexPath(of: asset.asset)
        self.didSelect(at: indexPath)
    }
    
    public func uncheck(asset: PhotoPickerWrapperAsset) {
        let indexPath = self.viewModel.indexPath(of: asset.asset)
        self.didDeselect(at: indexPath)
    }
    
    // MARK: DragSelectable
    private lazy var dragSelector: DragSelectable = DragSelector(collectionView: self.collectionView)
    private func implementDragSelectable() {
        self.dragSelector.addDragSelect { [weak self] didSelected, indexPath in
            if didSelected {
                self?.didSelect(at: indexPath)
            } else {
                self?.didDeselect(at: indexPath)
            }
        }
    }
    
    private func didSelect(at indexPath: IndexPath) {
        guard self.viewModel.didSelect(at: indexPath) else { return }
    }
    
    private func didDeselect(at indexPath: IndexPath) {
        self.viewModel.didDeselect(at: indexPath)
    }
}
// MARK: - UICollectionViewDataSource
extension MJPhotoPickerViewController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.viewModel.assets.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickerThumbnailCell", for: indexPath) as! PickerThumbnailCell
        let itemIdentifier = self.viewModel.assets[indexPath.item]
        let isSelected = self.viewModel.isSelected(at: indexPath)
        
        cell.bind(itemIdentifier, isSelected: isSelected)
        cell.checkIconSelectHandler = { [weak self] isSelected in
            if isSelected {
                self?.didDeselect(at: indexPath)
            } else {
                self?.didSelect(at: indexPath)
            }
        }
        return cell
    }
}
// MARK: - UICollectionViewDataSourcePrefetching
extension MJPhotoPickerViewController: UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView,
                               prefetchItemsAt indexPaths: [IndexPath]) {
        guard let layout = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout) else { return }

        var assets: [PHAsset] = []
        for indexPath in indexPaths {
            assets.append(self.viewModel.asset(of: indexPath))
        }
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: layout.itemSize.width * pow(scale, 1),
                                height: layout.itemSize.height * pow(scale, 1))
        PhotoService.startCachingImages(for: assets, size: targetSize)
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        guard let layout = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout) else { return }

        var assets: [PHAsset] = []
        for indexPath in indexPaths {
            assets.append(self.viewModel.asset(of: indexPath))
        }
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: layout.itemSize.width * pow(scale, 1),
                                height: layout.itemSize.height * pow(scale, 1))
        PhotoService.stopCachingImages(for: assets, size: targetSize)
    }
}
// MARK: - UICollectionViewDelegate
extension MJPhotoPickerViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
        let tappedAsseet = self.viewModel.didTap(at: indexPath)
        self.assetDidTapPublisher.send(.init(asset: tappedAsseet))
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               didDeselectItemAt indexPath: IndexPath) {
        let tappedAsseet = self.viewModel.didTap(at: indexPath)
        self.assetDidTapPublisher.send(.init(asset: tappedAsseet))
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
    }
}

extension MJPhotoPickerViewController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: self.viewModel.assets) else { return }
        Task { @MainActor in
            self.viewModel.photoLibraryDidChange(changes)
            if changes.hasIncrementalChanges {
                collectionView.performBatchUpdates({
                    
                    if let removed = changes.removedIndexes, !removed.isEmpty {
                        let indexPaths = removed.map { IndexPath(item: $0, section: 0) }
                        collectionView.deleteItems(at: indexPaths)
                    }
                    if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                        let indexPaths = inserted.map { IndexPath(item: $0, section: 0) }
                        collectionView.insertItems(at: indexPaths)
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                     to: IndexPath(item: toIndex, section: 0))
                    }
                }, completion: { [weak self] _ in
                    guard let self = self else { return }
                    if let changed = changes.changedIndexes, !changed.isEmpty {
                        let indexPaths = changed.map { IndexPath(item: $0, section: 0) }
                        self.collectionView.reloadItems(at: indexPaths)
                    }
                    self.viewModel.update(changes: changes)
                })
            } else {
                self.reloadData(animated: false)
                self.viewModel.update(changes: changes)
            }
            PhotoService.stopCachingAllImages()
        }
    }
}


