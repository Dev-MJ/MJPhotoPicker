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
    @Published var albumCellModels: [AssetAlbumListCellModel] = []
    // MARK: For Business (검색)
    private var initialAlbumCellModels: [AssetAlbumListCellModel] = []
    
    deinit {
        debugPrint("AssetAlbumListViewModel deinit")
    }
    
    func fetchAlbums() {
        Task {
            let userAlbumCollection = PhotoService.albumsCollection
            let favoriteCollection = PhotoService.favoriteCollection
            let mediaTypeCollections = PhotoService.mediaTypeCollections
            
            async let userAlbums = albumCellModels(in: userAlbumCollection)
            async let favoriteAlbum = albumCellModels(in: favoriteCollection)
            async let mediaTypeAlbums = albumCellModels(in: mediaTypeCollections)
            let albumCellModels = (await favoriteAlbum) + (await userAlbums) + (await mediaTypeAlbums)
            Task { @MainActor in
                self.albumCellModels = albumCellModels
                self.initialAlbumCellModels = albumCellModels
            }
        }
    }
    
    private func searchAlbums(text: String) {
        if text.isEmpty {
            self.albumCellModels = self.initialAlbumCellModels
                                            .map {
                                                $0.highlightText = nil
                                                return $0
                                            }
        } else {
            let album = self.initialAlbumCellModels
                .filter {
                    $0.title.lowercased().contains(text.lowercased())
                }.map {
                    $0.highlightText = text
                    return $0
                }
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
    
    private func albumCellModels(in collections: [PHAssetCollection]) async -> [AssetAlbumListCellModel] {
        return await withCheckedContinuation({ continuation in
            var cellModels: [AssetAlbumListCellModel] = collections.compactMap {
                let assets = PHAsset.fetchAssets(in: $0, options: nil)
                guard let asset = assets.firstObject else {
                    return nil
                }
                return AssetAlbumListCellModel(thumbnailAsset: asset,
                                               title: $0.localizedTitle ?? "",
                                               count: assets.count,
                                               type: .collection($0))
            }
            continuation.resume(returning: cellModels)
        })
    }
    
//    private func imagesAlbumCellModel() -> [AssetAlbumListCellModel] {
//        let assets = PhotoService.imageAssets()
//        guard let asset = assets.firstObject else { return [] }
//        return [AssetAlbumListCellModel(thumbnailAsset: asset,
//                                        title: Supply.allImagesTitle,
//                                        count: assets.count,
//                                        type: .custom(assets))]
//    }
//    
//    private func videosAlbumCellModel() -> [AssetAlbumListCellModel] {
//        let assets = PhotoService.videoAssets()
//        guard let asset = assets.firstObject else { return [] }
//        return [AssetAlbumListCellModel(thumbnailAsset: asset,
//                                        title: Supply.allVideosTitle,
//                                        count: assets.count,
//                                        type: .custom(assets))]
//    }
//    
//    private func allMediaAlbumCellModel() -> [AssetAlbumListCellModel] {
//        let assets = PhotoService.imageAndVideoAssets()
//        guard let asset = assets.firstObject else { return [] }
//        return [AssetAlbumListCellModel(thumbnailAsset: asset,
//                                        title: Supply.allMediasTitle,
//                                        count: assets.count,
//                                        type: .custom(assets))]
//    }
    
    func didSelect(cellModel: AssetAlbumListCellModel?) {
        selectedCellModel = cellModel
    }
}

final class MockAssetAlbumListViewModel: AssetAlbumListViewModelProtocol {
    @Published var selectedCellModel: AssetAlbumListCellModel?
//    @Published var mediaCellModels: [AssetAlbumListCellModel] = []
    @Published var albumCellModels: [AssetAlbumListCellModel] = []
    private var searchText: String = ""
    var searchTextBinding: Binding<String> {
        .init(get: { self.searchText }, set: { self.searchText = $0 })
    }
    
    func fetchAlbums() {
        albumCellModels = [.init(thumbnailAsset: PHAsset(),
                                 title: "스마트 앨범 ",
                                 count: 10000,
                                 type: .collection(.init())),]
    }
    
    func didSelect(cellModel: AssetAlbumListCellModel?) {
        
    }
}


extension PHAssetCollectionSubtype: CaseIterable {
    public static var allCases: [PHAssetCollectionSubtype] {
        var all: [PHAssetCollectionSubtype] = [.albumRegular,
                                               .albumSyncedEvent,
                                               .albumSyncedFaces,
                                               .albumSyncedAlbum,
                                               .albumImported,
                                               .albumMyPhotoStream,
                                               .albumCloudShared,
                                               .smartAlbumGeneric,
                                               .smartAlbumPanoramas,
                                               .smartAlbumVideos,
                                               .smartAlbumFavorites,
                                               .smartAlbumTimelapses,
                                               .smartAlbumAllHidden,
                                               .smartAlbumRecentlyAdded,
                                               .smartAlbumBursts,
                                               .smartAlbumSlomoVideos,
                                               .smartAlbumUserLibrary,
                                               .smartAlbumSelfPortraits,
                                               .smartAlbumScreenshots,
                                               .smartAlbumDepthEffect,
                                               .smartAlbumLivePhotos,
                                               .smartAlbumAnimated,
                                               .smartAlbumLongExposures,
                                               .smartAlbumUnableToUpload]
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, *) {
            all.append(contentsOf: [.smartAlbumRAW, .smartAlbumCinematic])
        }
        return all
    }
}
