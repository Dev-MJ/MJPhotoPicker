//
//  PhotoPickerWrapperAsset.swift
//  MJPhotoPicker
//
//  Created by mj.lee on 2023/11/02.
//

import Photos

public class PhotoPickerWrapperAsset {
    public private(set) var asset: PHAsset
    var id: String { asset.localIdentifier }
    
    init(asset: PHAsset) {
        self.asset = asset
    }
}

