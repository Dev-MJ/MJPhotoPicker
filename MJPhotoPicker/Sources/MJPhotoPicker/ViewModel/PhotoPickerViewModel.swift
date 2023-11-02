//
//  PhotoPickerViewModel.swift
//  MJPhotoPicker
//
//  Created by mj.lee on 2023/11/02.
//

import Photos
import Combine
import UIKit

final class PhotoPickerViewModel {
    private var configuration: PickerConfiguration
    @Published private(set) var selectedAssets: [PHAsset] = .init()
    @Published private(set) var assets: PHFetchResult<PHAsset> = .init()
    /**
     reloadData를 해야하는지 알려주는 Publisher
     
     true가 전달되면 animation효과가 있어야 함을 나타냄.
     */
    var reloadDataPublisher: AnyPublisher<Bool, Never> {
        self.reloadDataSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    private var reloadDataSubject: PassthroughSubject<Bool, Never> = .init()
    /**
     선택여부가 변경되었음을 알려주는 publisher.
     
     IndexPath에 해당하는 아이템이 선택되었는지(true), 미선택되었는지(false)를 전달한다.
     */
    var changedSelectionItemsPublisher: AnyPublisher<(Bool, IndexPath), Never> {
        self.changedSelectionItemsSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    private var changedSelectionItemsSubject: PassthroughSubject<(Bool, IndexPath), Never> = .init()
    private var assetSyncQueue = DispatchQueue(label: "PhotoPickerViewModelQueue")
    
    deinit {
        debugPrint("PhotoPickerViewModel deinit")
    }
    
    init(configuration: PickerConfiguration) {
        self.configuration = configuration
    }
    
    private func initalizeAssets(with newValue: PHFetchResult<PHAsset>) {
        self.assets = newValue
        self.selectedAssets = []
        self.reloadDataSubject.send(true)
    }
    
    // MARK: - Fetch
    
    func fetch() {
        let assets = PhotoService.fetchMediaAssets()
        self.initalizeAssets(with: assets)
    }
    
    func fetch(from collection: PHAssetCollection) {
        let assets = PhotoService.fetchAssets(in: collection)
        self.initalizeAssets(with: assets)
    }
    
    func fetch(from assets: PHFetchResult<PHAsset>) {
        self.initalizeAssets(with: assets)
    }
   
    // MARK: - Action
    
    func didTap(at indexPath: IndexPath) -> PHAsset {
        assets[indexPath.item]
    }
    
    func didSelect(at indexPath: IndexPath) -> Bool {
        let asset = assets[indexPath.item]
        self.didSelect(asset: asset)
        return true
    }
    
    func didDeselect(at indexPath: IndexPath) {
        let asset = assets[indexPath.item]
        self.didDeselect(asset: asset)
    }
    
    func didSelect(asset: PHAsset) {
        self.selectedAssets.append(asset)
        self.sendChangedIndexPath(at: asset, value: true)
    }
     
    func didDeselect(asset: PHAsset) {
        self.selectedAssets.removeAll { $0.localIdentifier == asset.localIdentifier }
        self.sendChangedIndexPath(at: asset, value: false)
    }
    
    // MARK: - Getter
    
    func index(of asset: PHAsset) -> Int {
        assets.index(of: asset)
    }
    
    func indexPath(of asset: PHAsset) -> IndexPath {
        IndexPath(item: self.index(of: asset), section: 0)
    }
    
    func asset(of indexPath: IndexPath) -> PHAsset {
        self.asset(of: indexPath.item)
    }
    
    func asset(of index: Int) -> PHAsset {
        assets.object(at: index)
    }
    
    func isSelected(asset: PHAsset) -> Bool {
        selectedAssets.contains(asset)
    }
    
    func isSelected(at indexPath: IndexPath) -> Bool {
        self.isSelected(at: indexPath.item)
    }
    
    func isSelected(at index: Int) -> Bool {
        let targetAsset = assets[index]
        return selectedAssets.contains(targetAsset)
    }

    private func sendChangedIndexPath(at asset: PHAsset, value: Bool) {
        let indexPath = self.indexPath(of: asset)
        self.changedSelectionItemsSubject.send((value, indexPath))
    }
    
    // MARK: - Auto Update Assets
    
    func update(changes: PHFetchResultChangeDetails<PHAsset>) {
        self.didRemoved(assets: changes.removedObjects)
        self.didChange(assets: changes.changedObjects)
    }
    
    private func didRemoved(assets: [PHAsset]) {
        guard !assets.isEmpty else { return }
        self.assetSyncQueue.async {
            self.selectedAssets = self.selectedAssets.filter {
                !assets.contains($0)
            }
            for asset in assets {
                self.sendChangedIndexPath(at: asset, value: false)
            }
        }
    }
    
    private func didChange(assets: [PHAsset]) {
        guard !assets.isEmpty else { return }
        self.assetSyncQueue.async {
            self.selectedAssets = self.selectedAssets.map { selectedAsset in
                guard let a = (assets.first { selectedAsset == $0 }) else {
                    return selectedAsset
                }
                return a
            }
            
            for asset in assets {
                let isSelected = self.isSelected(asset: asset)
                self.sendChangedIndexPath(at: asset, value: isSelected)
            }
        }
    }
    
    // MARK: - Photo Library Observer From MJPhotoPickerViewController
    
    func photoLibraryDidChange(_ changes: PHFetchResultChangeDetails<PHAsset>) {
        self.assets = changes.fetchResultAfterChanges
    }
}

