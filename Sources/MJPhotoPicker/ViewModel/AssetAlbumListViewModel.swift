//
//  AssetAlbumListViewModel.swift
//  MJPhotoPicker
//
//  Created by mj.lee on 2023/11/02.
//

import Photos
import SwiftUI

protocol AssetAlbumListViewModelProtocol: ObservableObject {
    var selectedCellModel: AssetAlbumListCellModel? { get }
    var mediaCellModels: [AssetAlbumListCellModel] { get }
    var albumCellModels: [AssetAlbumListCellModel] { get }
    
    func fetchAlbums()
    func didSelect(cellModel: AssetAlbumListCellModel?)
    var searchTextBinding: Binding<String> { get }
}

final class AssetAlbumListViewModel: AssetAlbumListViewModelProtocol {
    private var searchText: String = "" {
        didSet {
            self.searchAlbums(text: self.searchText)
        }
    }
    var searchTextBinding: Binding<String> {
        .init(get: { self.searchText },
              set: {
            guard self.searchText != $0 else { return }
            self.searchText = $0
        })
    }
    // MARK: For UI
    @Published var selectedCellModel: AssetAlbumListCellModel?
    @Published var mediaCellModels: [AssetAlbumListCellModel] = []
    @Published var albumCellModels: [AssetAlbumListCellModel] = []
    // MARK: For Business (검색)
    private var initialMediaCellModels: [AssetAlbumListCellModel] = []
    private var initialAlbumCellModels: [AssetAlbumListCellModel] = []
    
    deinit {
        debugPrint("AssetAlbumListViewModel deinit")
    }
    
    func fetchAlbums() {
        Task {
            let albumCollection = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                          subtype: .any,
                                                                          options: nil)
            let anyCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                        subtype: .any,
                                                                        options: nil)
            async let albums = albumCellModels(in: albumCollection)
            async let any = albumCellModels(in: anyCollection)
            let mediaCellModels = self.allMediaAlbumCellModel() + self.videosAlbumCellModel() + self.imagesAlbumCellModel()
            let albumCellModels = (await albums) + (await any)
            Task { @MainActor in
                self.mediaCellModels = mediaCellModels
                self.albumCellModels = albumCellModels
                self.initialMediaCellModels = mediaCellModels
                self.initialAlbumCellModels = albumCellModels
            }
        }
    }
    
    private func searchAlbums(text: String) {
        if text.isEmpty {
            self.mediaCellModels = self.initialMediaCellModels
                                            .map {
                                                $0.highlightText = nil
                                                return $0
                                            }
            self.albumCellModels = self.initialAlbumCellModels
                                            .map {
                                                $0.highlightText = nil
                                                return $0
                                            }
        } else {
            let media = self.initialMediaCellModels
                .filter {
                    $0.title.lowercased().contains(text.lowercased())
                }.map {
                    $0.highlightText = text
                    return $0
                }
            let album = self.initialAlbumCellModels
                .filter {
                    $0.title.lowercased().contains(text.lowercased())
                }.map {
                    $0.highlightText = text
                    return $0
                }
            self.mediaCellModels = media + album
            self.albumCellModels = []
        }
    }
    
    private func albumCellModels(in collections: PHFetchResult<PHAssetCollection>) async -> [AssetAlbumListCellModel] {
        return await withCheckedContinuation({ continuation in
            var cellModels: [AssetAlbumListCellModel] = []
            collections.enumerateObjects { collection, _, _ in
                let assets = PHAsset.fetchAssets(in: collection, options: nil)
                if let asset = assets.firstObject {
                    cellModels.append(.init(thumbnailAsset: asset,
                                            title: collection.localizedTitle ?? "",
                                            count: assets.count,
                                            type: .collection(collection)))
                }
            }
            continuation.resume(returning: cellModels)
        })
    }
    
    private func imagesAlbumCellModel() -> [AssetAlbumListCellModel] {
        let assets = PhotoService.imageAssets()
        guard let asset = assets.firstObject else { return [] }
        return [AssetAlbumListCellModel(thumbnailAsset: asset,
                                        title: Supply.allImagesTitle,
                                        count: assets.count,
                                        type: .custom(assets))]
    }
    
    private func videosAlbumCellModel() -> [AssetAlbumListCellModel] {
        let assets = PhotoService.videoAssets()
        guard let asset = assets.firstObject else { return [] }
        return [AssetAlbumListCellModel(thumbnailAsset: asset,
                                        title: Supply.allVideosTitle,
                                        count: assets.count,
                                        type: .custom(assets))]
    }
    
    private func allMediaAlbumCellModel() -> [AssetAlbumListCellModel] {
        let assets = PhotoService.imageAndVideoAssets()
        guard let asset = assets.firstObject else { return [] }
        return [AssetAlbumListCellModel(thumbnailAsset: asset,
                                        title: Supply.allMediasTitle,
                                        count: assets.count,
                                        type: .custom(assets))]
    }
    
    func didSelect(cellModel: AssetAlbumListCellModel?) {
        selectedCellModel = cellModel
    }
}

final class MockAssetAlbumListViewModel: AssetAlbumListViewModelProtocol {
    @Published var selectedCellModel: AssetAlbumListCellModel?
    @Published var mediaCellModels: [AssetAlbumListCellModel] = []
    @Published var albumCellModels: [AssetAlbumListCellModel] = []
    private var searchText: String = ""
    var searchTextBinding: Binding<String> {
        .init(get: { self.searchText }, set: { self.searchText = $0 })
    }
    
    func fetchAlbums() {
        mediaCellModels = [.init(thumbnailAsset: PHAsset(),
                                 title: Supply.allMediasTitle,
                                 count: 200000,
                                 type: .custom(.init())),
                           .init(thumbnailAsset: PHAsset(),
                                 title: Supply.allImagesTitle,
                                 count: 100000,
                                 type: .custom(.init())),
                           .init(thumbnailAsset: PHAsset(),
                                 title: Supply.allVideosTitle,
                                 count: 100000,
                                 type: .custom(.init())),]
        albumCellModels = [.init(thumbnailAsset: PHAsset(),
                                 title: "스마트 앨범 ",
                                 count: 10000,
                                 type: .collection(.init())),]
    }
    
    func didSelect(cellModel: AssetAlbumListCellModel?) {
        
    }
}

