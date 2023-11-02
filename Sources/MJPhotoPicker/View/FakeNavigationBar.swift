//
//  FakeNavigationBar.swift
//  MJPhotoPicker
//
//  Created by mj.lee on 2023/11/02.
//

import UIKit
import Combine

final class FakeNavigationBar: UIView {
    let closeTapPublisher: PassthroughSubject<(), Never> = .init()
    let titleTapPublisher: PassthroughSubject<(), Never> = .init()
    
    private let backView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let backButton: UIButton = {
        let b = UIButton()
        b.setImage(Supply.closeIcon, for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    private let titleButton: UIButton = {
        let b = UIButton()
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.setTitle(Supply.allMediasTitle, for: .normal)
        b.setImage(Supply.albumTitleImage?.withRenderingMode(.alwaysOriginal),
                   for: .normal)
        b.semanticContentAttribute = .forceRightToLeft
        b.contentHorizontalAlignment = .left
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubviews()
        self.configureConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addSubviews()
        self.configureConstraints()
    }
    
    private func addSubviews() {
        addSubview(self.backView)
        self.backView.addSubview(self.backButton)
        self.backView.addSubview(self.titleButton)
        
        self.backButton.addAction(.init(handler: { [weak self] action in
            guard let self = self else { return }
            self.closeTapPublisher.send()
        }), for: .touchUpInside)
        
        self.titleButton.addAction(.init(handler: { [weak self] action in
            guard let self = self else { return }
            self.titleTapPublisher.send()
        }), for: .touchUpInside)
    }
    
    private func configureConstraints() {
        NSLayoutConstraint.activate([
            self.backView.widthAnchor.constraint(equalTo: self.widthAnchor),
            self.backView.heightAnchor.constraint(equalTo: self.heightAnchor),
            self.backView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.backView.topAnchor.constraint(equalTo: self.topAnchor),
            
            self.backButton.widthAnchor.constraint(equalTo: self.backButton.heightAnchor, multiplier: 1),
            self.backButton.heightAnchor.constraint(equalTo: self.backView.heightAnchor),
            self.backButton.leadingAnchor.constraint(equalTo: self.backView.leadingAnchor),
            self.backButton.topAnchor.constraint(equalTo: self.backView.topAnchor),
            
            self.titleButton.leadingAnchor.constraint(equalTo: self.backButton.trailingAnchor, constant: 0),
            self.titleButton.trailingAnchor.constraint(equalTo: self.backView.trailingAnchor, constant: -16),
            self.titleButton.centerYAnchor.constraint(equalTo: self.backView.centerYAnchor),
        ])
    }
    
    func setTitle(_ title: String) {
        self.titleButton.setTitle(title, for: .normal)
    }
}
