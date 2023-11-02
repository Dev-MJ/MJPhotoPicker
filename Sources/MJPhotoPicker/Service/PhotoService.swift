//
//  PhotoService.swift
//  MJPhotoPicker
//
//  Created by mj.lee on 2023/11/02.
//

import Photos
import UIKit

final actor PhotoService {
    static private let imageManager = PHCachingImageManager()
    
    private init() {}
    
    static var albumsCollection: PHFetchResult<PHAssetCollection> {
        PHAssetCollection.fetchAssetCollections(with: .album,
                                                subtype: .any,
                                                options: nil)
    }
    
    static var smartAlbumAnyCollection: PHFetchResult<PHAssetCollection> {
        PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                subtype: .any,
                                                options: nil)
    }
    
    static func imageAssets() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: .image, options: options)
    }
    
    static func videoAssets() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: .video, options: options)
    }
    
    static func imageAndVideoAssets() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.video.rawValue, PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(with: options)
    }
    
    static func fetchAssets(in collection: PHAssetCollection) -> PHFetchResult<PHAsset> {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(in: collection, options: fetchOptions)
    }
    
    static func fetchMediaAssets() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
        options.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d || mediaType = %d", PHAssetMediaType.video.rawValue, PHAssetMediaType.image.rawValue, PHAssetMediaType.unknown.rawValue)
        return PHAsset.fetchAssets(with: options)
    }
    
    static func requestCachedImage(for asset: PHAsset, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast  // .exact: 일부 썸네일이 노출안되는 현상이 있음
        options.version = .current
        options.isSynchronous = false
        self.imageManager.requestImage(for: asset,
                                       targetSize: size,
                                       contentMode: .aspectFill,
                                       options: options) { image, info in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    static func startCachingImages(for assets: [PHAsset], size: CGSize) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.version = .current
        options.isSynchronous = false
        self.imageManager.startCachingImages(for: assets,
                                             targetSize: size,
                                             contentMode: .aspectFill,
                                             options: nil)
    }
    
    static func stopCachingImages(for assets: [PHAsset], size: CGSize) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.version = .current
        options.isSynchronous = false
        self.imageManager.stopCachingImages(for: assets,
                                            targetSize: size,
                                            contentMode: .aspectFill,
                                            options: options)
    }
    
    static func cancelImageRequest(id: PHImageRequestID) {
        self.imageManager.cancelImageRequest(id)
    }
    
    static func stopCachingAllImages() {
        self.imageManager.stopCachingImagesForAllAssets()
    }
    
//    static func requestCachedImage(for asset: PHAsset, size: CGSize) async -> UIImage? {
//        let options = PHImageRequestOptions()
//        options.isNetworkAccessAllowed = true
//        options.deliveryMode = .fastFormat
//        options.resizeMode = .exact
//        options.version = .current
//        return await withCheckedContinuation { continuation in
//            PHCachingImageManager.default().requestImage(for: asset,
//                                                         targetSize: size,
//                                                         contentMode: .aspectFill,
//                                                         options: options) { image, _ in
//                continuation.resume(returning: image)
//            }
//        }
//    }
}

