//
//  PickerThumbnailCell.swift
//  MJPhotoPicker
//
//  Created by mj.lee on 2023/11/02.
//

import UIKit
import Combine
import Photos

final class PickerThumbnailCell: UICollectionViewCell {
    private var backView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private var thumbnailView: UIImageView = {
        let v = UIImageView(frame: .zero)
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        return v
    }()
    private var selectionView: UIView = {
        let v = UIView(frame: .zero)
        v.backgroundColor = Supply.selectionOverlayColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private var checkIcon: UIButton = {
        let b = UIButton(frame: .zero)
        b.setImage(Supply.photoSelectedIcon, for: .selected)
        b.setImage(Supply.photoDeselectedIcon, for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private var subscriptions: Set<AnyCancellable> = .init()
    override var reuseIdentifier: String { "PickerThumbnailCell" }
    private var assetIdentifier: String?
    var checkIconSelectHandler: ((Bool) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubvews()
        self.configureConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addSubvews()
        self.configureConstraints()
    }
    
    private func addSubvews() {
        contentView.addSubview(backView)
        backView.addSubview(thumbnailView)
        backView.addSubview(selectionView)
        backView.addSubview(checkIcon)
    }
    
    private func configureConstraints() {
        NSLayoutConstraint.activate([
            self.backView.widthAnchor.constraint(equalTo: self.contentView.widthAnchor),
            self.backView.heightAnchor.constraint(equalTo: self.contentView.heightAnchor),
            self.backView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.backView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            
            self.thumbnailView.widthAnchor.constraint(equalTo: self.backView.widthAnchor),
            self.thumbnailView.heightAnchor.constraint(equalTo: self.backView.heightAnchor),
            self.thumbnailView.leadingAnchor.constraint(equalTo: self.backView.leadingAnchor),
            self.thumbnailView.topAnchor.constraint(equalTo: self.backView.topAnchor),
            
            self.selectionView.widthAnchor.constraint(equalTo: self.backView.widthAnchor),
            self.selectionView.heightAnchor.constraint(equalTo: self.backView.heightAnchor),
            self.selectionView.leadingAnchor.constraint(equalTo: self.backView.leadingAnchor),
            self.selectionView.topAnchor.constraint(equalTo: self.backView.topAnchor),
            
            self.checkIcon.widthAnchor.constraint(equalToConstant: 24),
            self.checkIcon.heightAnchor.constraint(equalToConstant: 24),
            self.checkIcon.trailingAnchor.constraint(equalTo: self.backView.trailingAnchor, constant: -10),
            self.checkIcon.topAnchor.constraint(equalTo: self.backView.topAnchor, constant: 10),
        ])
    }
    
    override var isSelected: Bool {
        didSet {
            configure(isSelected)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.subscriptions = .init()
        self.reset()
    }
    
    func bind(_ asset: PHAsset, isSelected: Bool = false) {
        self.isSelected = isSelected
        self.assetIdentifier = asset.localIdentifier
        
        let width = self.thumbnailView.frame.width * pow(UIScreen.main.scale, 1)
        let size = CGSize(width: width, height: width)
        PhotoService.requestCachedImage(for: asset, size: size) { [weak self] image in
            guard let self = self else { return }
            guard self.assetIdentifier == asset.localIdentifier else { return }
            self.thumbnailView.image = image
        }
        checkIcon.addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }
    
    private func configure(_ selected: Bool) {
        self.selectionView.isHidden = !selected
        self.checkIcon.isSelected = selected
    }
    
    private func reset() {
        selectionView.isHidden = true
        checkIcon.isSelected = false
//        thumbnailView.image = nil
        checkIcon.removeTarget(self, action: #selector(didTap), for: .touchUpInside)
    }
    
    @objc private func didTap() {
        checkIconSelectHandler?(checkIcon.isSelected)
    }
}


