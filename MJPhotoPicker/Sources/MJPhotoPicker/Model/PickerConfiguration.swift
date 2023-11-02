//
//  PickerConfiguration.swift
//  MJPhotoPicker
//
//  Created by mj.lee on 2023/11/02.
//

import UIKit
import SwiftUI

public struct PickerConfiguration {
    // 앨범 목록
    public var allImagesTitle: String
    public var allVideosTitle: String
    public var allMediasTitle: String
    public var searchPlaceholder: String
    public var searchFieldBackgroundColor: UIColor
    public var albumTitleImage: UIImage?
    public var closeIcon: UIImage?
    public var albumSectionDividerTitle: String
    // 앨범 상세
    public var photoSelectedIcon: UIImage?
    public var photoDeselectedIcon: UIImage?
    public var selectionOverlayColor: UIColor

    public init(allImagesTitle: String = "All Images",
                allVideosTitle: String = "All Videos",
                allMediasTitle: String = "All Medias",
                searchPlaceholder: String = "search albums...",
                searchFieldBackgroundColor: UIColor = .lightGray,
                albumTitleImage: UIImage? = .init(systemName: "arrowtriangle.down.fill"),
                closeIcon: UIImage? = .init(systemName: "xmark"),
                albumSectionDividerTitle: String = "Albums",
                photoSelectedIcon: UIImage? = .init(systemName: "checkmark.circle.fill"),
                photoDeselectedIcon: UIImage? = .init(systemName: "checkmark.circle"),
                selectionOverlayColor: UIColor = .init(red: 64/255, green: 120/255, blue: 255/255, alpha: 0.4)) {
        self.allImagesTitle = allImagesTitle
        self.allVideosTitle = allVideosTitle
        self.allMediasTitle = allMediasTitle
        self.searchPlaceholder = searchPlaceholder
        self.searchFieldBackgroundColor = searchFieldBackgroundColor
        self.albumTitleImage = albumTitleImage
        self.closeIcon = closeIcon
        self.albumSectionDividerTitle = albumSectionDividerTitle
        
        self.photoSelectedIcon = photoSelectedIcon
        self.photoDeselectedIcon = photoDeselectedIcon
        self.selectionOverlayColor = selectionOverlayColor
    }
    
    func updateSupply() {
        Supply.allImagesTitle = self.allImagesTitle
        Supply.allVideosTitle = self.allVideosTitle
        Supply.allMediasTitle = self.allMediasTitle
        Supply.searchPlaceholder = self.searchPlaceholder
        Supply.searchFieldBackgroundColor = self.searchFieldBackgroundColor
        Supply.albumTitleImage = self.albumTitleImage
        Supply.closeIcon = self.closeIcon
        Supply.albumSectionDividerTitle = self.albumSectionDividerTitle
        
        Supply.photoSelectedIcon = self.photoSelectedIcon
        Supply.photoDeselectedIcon = self.photoDeselectedIcon
        Supply.selectionOverlayColor = self.selectionOverlayColor
    }
}

struct Supply {
    // 앨범 목록
    static var allImagesTitle: String = "All Images"
    static var allVideosTitle: String = "All Videos"
    static var allMediasTitle: String = "All Medias"
    static var searchPlaceholder: String = "search albums..."
    static var searchFieldBackgroundColor: UIColor = .lightGray
    static var albumTitleImage: UIImage? = .init(systemName: "arrowtriangle.down.fill")
    static var closeIcon: UIImage? = .init(systemName: "xmark")
    static var albumSectionDividerTitle: String = "앨범"
    // 앨범 상세
    static var photoSelectedIcon: UIImage? = .init(systemName: "checkmark.circle.fill")
    static var photoDeselectedIcon: UIImage? = .init(systemName: "checkmark.circle")
    static var selectionOverlayColor: UIColor = .init(red: 64/255, green: 120/255, blue: 255/255, alpha: 0.4)
}


