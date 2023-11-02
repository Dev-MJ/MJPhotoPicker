//
//  DragSelector.swift
//  MJPhotoKit
//
//  Created by mj.lee on 2023/11/02.
//

import UIKit
import Combine

struct DragSelectSupplyments {
    /// 첫 시작 아이템이 선택된 상태인지 여부
    var isSelectedStartItem: Bool = false
    /// 첫 시작 indexPath
    var draggingStartIndexPath: IndexPath?
    /// 단일 selection
    var thisSelectedIndexPaths: Set<IndexPath> = []
    
    var panY: CGFloat = 0
    let autoscrollAreaHeight: CGFloat = 100
    let safeAreaInsets: UIEdgeInsets = {
        if #available(iOS 15.0, *) {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            return windowScene?.windows.first?.safeAreaInsets ?? .zero
        } else {
            return UIApplication.shared.windows.first?.safeAreaInsets ?? .zero
        }
    }()
}

final class DragSelector: NSObject, DragSelectable {
    private lazy var autoScrollDisplayLink: CADisplayLink = {
        let l = CADisplayLink(target: self, selector: #selector(handleAutoScrollDisplayLink))
        l.add(to: .main, forMode: .default)
        l.isPaused = true
        return l
    }()
    private weak var collectionView: UICollectionView?
    // MARK: DragSelectable
    var supplyments: DragSelectSupplyments = .init()

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
    
    deinit {
        debugPrint("DragSelector deinit")
    }
    
    func addDragSelect(handler: @escaping ((Bool, IndexPath) -> Void)) {
        let gesture = BindablePanGestureRecognizer { [weak self] gesture in
            guard let self = self else { return }
            guard let collectionView = self.collectionView else { return }
            guard let currentIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else { return }
            self.initializeProperties(with: gesture, in: collectionView, indexPath: currentIndexPath)
            self.autoScrollIfPossible(with: gesture)
            
            if self.isCrossed(with: currentIndexPath) {
                self.goCross(in: collectionView, handler: handler)
            }
            if self.isGoingDown(to: currentIndexPath) {
                self.goDown(to: currentIndexPath, in: collectionView, handler: handler)
            }
            if self.isGoingUp(to: currentIndexPath) {
                self.goUp(to: currentIndexPath, in: collectionView, handler: handler)
            }
        }
        if let collectionView = self.collectionView {
            let index = collectionView.gestureRecognizers?.firstIndex(of: collectionView.panGestureRecognizer) ?? 0
            collectionView.gestureRecognizers?.insert(gesture, at: index)
        }
    }
}

// MARK: Auto Scroll
extension DragSelector {
    private func didAccessGoDownArea(in collectionView: UICollectionView) -> Bool {
        supplyments.panY > collectionView.frame.maxY - supplyments.autoscrollAreaHeight
    }
    private func didAccessGoUpArea(in collectionView: UICollectionView) -> Bool {
        supplyments.panY < collectionView.frame.minY + supplyments.autoscrollAreaHeight
    }
    @objc private func handleAutoScrollDisplayLink() {
        guard let collectionView else { return }
        let speed: CGFloat = 10
        if didAccessGoDownArea(in: collectionView) {
            let nextYOffset = collectionView.contentOffset.y + speed
            if nextYOffset > collectionView.contentSize.height - collectionView.frame.size.height + supplyments.safeAreaInsets.bottom + speed { return }
            
            collectionView.contentOffset.y = nextYOffset
        } else if didAccessGoUpArea(in: collectionView) {
            let nextYOffset = collectionView.contentOffset.y - speed
            if nextYOffset < -(speed + supplyments.safeAreaInsets.top) || nextYOffset < 0 { return }
            
            collectionView.contentOffset.y = nextYOffset
        }
    }
    
    private func autoScrollIfPossible(with gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.autoScrollDisplayLink.isPaused = false
        case .changed:
            guard let collectionView else { return }
            guard didAccessGoUpArea(in: collectionView) || didAccessGoDownArea(in: collectionView) else {
                self.autoScrollDisplayLink.isPaused = true
                return
            }
            self.autoScrollDisplayLink.isPaused = false
        case .ended:
            self.autoScrollDisplayLink.isPaused = true
        default: break
        }
    }
}

protocol DragSelectable: AnyObject {
    var supplyments: DragSelectSupplyments { get set }
    init(collectionView: UICollectionView)
    func addDragSelect(handler: @escaping ((Bool, IndexPath) -> Void))
}

extension DragSelectable {
    func initializeProperties(with gesture: UIPanGestureRecognizer,
                              in collectionView: UICollectionView,
                              indexPath: IndexPath) {
        switch gesture.state {
        case .began:
            self.supplyments.isSelectedStartItem = collectionView.cellForItem(at: indexPath)?.isSelected ?? false
            self.supplyments.draggingStartIndexPath = indexPath
        case .changed:
            break
        case .ended:
            self.supplyments.draggingStartIndexPath = nil
            self.supplyments.thisSelectedIndexPaths.removeAll()
        default:
            break
        }
        self.supplyments.panY = gesture.location(in: nil).y
    }
    
    func isGoingUp(to currentIndexPath: IndexPath) -> Bool {
        guard let draggingStartIndexPath = supplyments.draggingStartIndexPath else { return false }
        return currentIndexPath.item <= draggingStartIndexPath.item
    }
    
    func isGoingDown(to currentIndexPath: IndexPath) -> Bool {
        guard let draggingStartIndexPath = supplyments.draggingStartIndexPath else { return false }
        return currentIndexPath.item >= draggingStartIndexPath.item
    }
    
    func goUp(to currentIndexPath: IndexPath, in collectionView: UICollectionView, handler: ((Bool, IndexPath) -> Void)) {
        guard let draggingStartIndexPath = supplyments.draggingStartIndexPath else { return }
        for cell in collectionView.visibleCells {
            if let indexPath = collectionView.indexPath(for: cell) {
                // start 위치로 back
                if indexPath.item < currentIndexPath.item &&
                    self.supplyments.thisSelectedIndexPaths.contains(indexPath) {
                    handler(self.supplyments.isSelectedStartItem, indexPath)
                    self.supplyments.thisSelectedIndexPaths.remove(indexPath)
                }
                // new
                if indexPath.item <= draggingStartIndexPath.item &&
                    indexPath.item >= currentIndexPath.item {
                    if cell.isSelected == self.supplyments.isSelectedStartItem && !self.supplyments.thisSelectedIndexPaths.contains(indexPath) {
                        handler(!self.supplyments.isSelectedStartItem, indexPath)
                        self.supplyments.thisSelectedIndexPaths.insert(indexPath)
                    }
                }
            }
        }
    }
    
    func goDown(to currentIndexPath: IndexPath, in collectionView: UICollectionView, handler: ((Bool, IndexPath) -> Void)) {
        guard let startIndexPath = supplyments.draggingStartIndexPath else { return }
        for cell in collectionView.visibleCells {
            if let indexPath = collectionView.indexPath(for: cell) {
                // start 위치로 back
                if indexPath.item > currentIndexPath.item &&
                    self.supplyments.thisSelectedIndexPaths.contains(indexPath) {
                    handler(self.supplyments.isSelectedStartItem, indexPath)
                    self.supplyments.thisSelectedIndexPaths.remove(indexPath)
                }
                // new
                if indexPath.item >= startIndexPath.item &&
                    indexPath.item <= currentIndexPath.item {
                    if cell.isSelected == self.supplyments.isSelectedStartItem, !self.supplyments.thisSelectedIndexPaths.contains(indexPath) {
                        handler(!self.supplyments.isSelectedStartItem, indexPath)
                        self.supplyments.thisSelectedIndexPaths.insert(indexPath)
                    }
                }
            }
        }
    }
    
    func isCrossed(with currentIndexPath: IndexPath) -> Bool {
        guard let draggingStartIndexPath = supplyments.draggingStartIndexPath else { return false }
        for indexPath in self.supplyments.thisSelectedIndexPaths {
            if (currentIndexPath.item < draggingStartIndexPath.item &&
                indexPath.item > draggingStartIndexPath.item) ||
                (currentIndexPath.item > draggingStartIndexPath.item &&
                 indexPath.item < draggingStartIndexPath.item) {
                return true
            }
        }
        return false
    }
    
    func goCross(in collectionView: UICollectionView, handler: ((Bool, IndexPath) -> Void)) {
        guard let draggingStartIndexPath = supplyments.draggingStartIndexPath else { return }
        for indexPath in self.supplyments.thisSelectedIndexPaths {
            if indexPath != draggingStartIndexPath {
                handler(self.supplyments.isSelectedStartItem, indexPath)
                self.supplyments.thisSelectedIndexPaths.remove(indexPath)
            }
        }
    }
}

fileprivate final class BindablePanGestureRecognizer: UIPanGestureRecognizer {
    private var action: ((UIPanGestureRecognizer) -> Void)?

    deinit {
        debugPrint("BindablePanGestureRecognizer deinit")
    }

    init(action: ((UIPanGestureRecognizer) -> Void)?) {
        self.action = action
        super.init(target: nil, action: nil)
        self.addTarget(self, action: #selector(execute))
    }

    @objc private func execute(gesture: UIPanGestureRecognizer) {
        action?(gesture)
    }
}

