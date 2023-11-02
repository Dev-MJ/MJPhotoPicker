//
//  AssetAlbumListCell.swift
//  MJPhotoPicker
//
//  Created by mj.lee on 2023/11/02.
//

import SwiftUI

struct AssetAlbumListCell: View {
    @Environment(\.isPreview) var isPreview
    @StateObject var cellModel: AssetAlbumListCellModel
    
    var body: some View {
        HStack {
            if let image = cellModel.thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cellModel.width, height: cellModel.width)
                    .cornerRadius(10)
                    .padding(.leading, 16)
            } else {
                Rectangle()
                    .frame(width: cellModel.width, height: cellModel.width)
                    .cornerRadius(10)
                    .padding(.leading, 16)
            }
                
            Text(cellModel.title)
                .lineLimit(1)
                .padding(.leading, 12)
            
            Spacer()
            
            Text("\(cellModel.photoCount)")
                .padding(.trailing, 8)
                .padding(.leading, 13)
        }
        .font(.system(size: 16, weight: .medium))
        .onAppear {
            if !isPreview {
                // preview에서 크래시
                cellModel.requestImage()
            }
        }
        .onDisappear {
            cellModel.clearImage()
        }
    }
}

#if DEBUG
extension EnvironmentValues {
    var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

import Photos
struct AlbumListCell_Previews: PreviewProvider {
    static var previews: some View {
        AssetAlbumListCell(cellModel: .init(thumbnailAsset: PHAsset(), title: "타이틀123123123123123123123455555555555557845678567856785678567856785678", count: 123, type: .custom(.init())))
    }
}
#endif

