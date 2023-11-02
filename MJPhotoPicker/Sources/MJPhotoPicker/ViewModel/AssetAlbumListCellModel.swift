//
//  AlbumListCellModel.swift
//  MJPhotoPicker
//
//  Created by mj.lee on 2023/11/02.
//

import UIKit
import Photos

final class AssetAlbumListCellModel: ObservableObject {
    enum `Type` {
        case custom(PHFetchResult<PHAsset>)
        case collection(PHAssetCollection)
    }
    
    private var id: String
    private(set) var thumbnailAsset: PHAsset
    private(set) var type: `Type`
    @Published var thumbnail: UIImage?
    @Published var title: String
    @Published var highlightText: String?
    @Published var photoCount: Int
    let width: CGFloat = 50
    
    init(thumbnailAsset: PHAsset, title: String, count: Int, type: `Type`) {
        self.thumbnailAsset = thumbnailAsset
        self.title = title
        self.photoCount = count
        self.type = type
        switch type {
        case .collection(let collection):
            self.id = collection.localIdentifier
        case .custom(_):
            self.id = UUID().uuidString
        }
    }
    
    
    func requestImage() {
//        Task { @MainActor in
//            self.thumbnail = await self.requestImage()
//        }
        
        let size = CGSize(width: width * pow(UIScreen.main.scale, 1), height: width * pow(UIScreen.main.scale, 1))
        PhotoService.requestCachedImage(for: thumbnailAsset, size: size, completion: { [weak self] image in
            self?.thumbnail = image
        })
    }
    
//    private func requestImage() async -> UIImage? {
//        await PhotoService.requestCachedImage(for: thumbnailAsset,
//                                                size: .init(width: 30, height: 30))
//    }
    
    func clearImage() {
        Task { @MainActor in
            self.thumbnail = nil
        }
    }
}

extension AssetAlbumListCellModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AssetAlbumListCellModel, rhs: AssetAlbumListCellModel) -> Bool {
        lhs.id == rhs.id
    }
}
