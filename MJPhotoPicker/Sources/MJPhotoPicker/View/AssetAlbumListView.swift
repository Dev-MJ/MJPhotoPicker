//
//  AssetAlbumListView.swift
//  MJPhotoPicker
//
//  Created by mj.lee on 2023/11/02.
//

import SwiftUI
import Photos

struct AssetAlbumListView<VM>: View where VM: AssetAlbumListViewModelProtocol {
    @ObservedObject var viewModel: VM
    @State private var animated: Bool = false

    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .foregroundColor(Color(Supply.searchFieldBackgroundColor))
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField(Supply.searchPlaceholder, text: viewModel.searchTextBinding)
                }
                .foregroundColor(.gray)
                .padding(.leading, 13)
            }
            .frame(height: 40)
            .cornerRadius(13)
            .padding()
            
            ScrollView {
                LazyVStack(alignment: .leading) {
                    //            List {
                    ForEach(viewModel.mediaCellModels, id: \.self) { cellModel in
                        AssetAlbumListCell(cellModel: cellModel)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.didSelect(cellModel: cellModel)
                            }
                            .frame(height: 68)
                            
                    }
                    
                    if !viewModel.albumCellModels.isEmpty {
                        Text(Supply.albumSectionDividerTitle)
                            .padding(.leading, 16)
                            .frame(height: 44)
                            .font(.system(size: 16, weight: .medium))
                        
                        ForEach(viewModel.albumCellModels, id: \.self) { cellModel in
                            AssetAlbumListCell(cellModel: cellModel)
                                .onTapGesture {
                                    viewModel.didSelect(cellModel: cellModel)
                                }
                                .frame(height: 68)
                        }
                    }
                }
            }
            .opacity(animated ? 1.0 : 0)
            .onAppear {
                viewModel.fetchAlbums()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        animated = true
                    }
                }
            }
        }
    }
}

struct AssetAlbumListView_Previews: PreviewProvider {
    static var previews: some View {
        AssetAlbumListView(viewModel: MockAssetAlbumListViewModel())
    }
}

