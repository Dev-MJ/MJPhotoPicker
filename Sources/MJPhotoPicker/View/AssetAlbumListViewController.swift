//
//  AssetAlbumListViewController.swift
//  MJPhotoPicker
//
//  Created by mj.lee on 2023/11/02.
//

import UIKit
import SwiftUI
import Combine

final class AssetAlbumListViewController: UIViewController {
    private var viewModel: AssetAlbumListViewModel = .init()
    private var subscriptions: Set<AnyCancellable> = .init()
    var selectedAlbumWillChangePublisher: AnyPublisher<(title: String, type: AssetAlbumListCellModel.`Type`), Never> {
        viewModel.$selectedCellModel
            .compactMap { $0 }
            .compactMap { ($0.title, $0.type) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    deinit {
        debugPrint("AssetAlbumListViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.addHosting()
        
        self.selectedAlbumWillChangePublisher
            .sink { [weak self] _ in
                self?.dismiss(animated: true)
            }.store(in: &subscriptions)
    }
    
    private func addHosting() {
        let hosting = UIHostingController(rootView: AssetAlbumListView(viewModel: viewModel))
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
        
        self.configureConstrinats(hosting: hosting)
    }
    
    private func configureConstrinats(hosting: UIHostingController<AssetAlbumListView<AssetAlbumListViewModel>>) {
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            hosting.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
        ])
    }
}

