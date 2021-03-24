//
//  ViewManager.swift
//  CardView
//
//  Created by YYKJ on 2020/10/20.
//  Copyright © 2020 YYKJ. All rights reserved.
//

import UIKit
import Foundation

class ViewManager: NSObject {
    enum State {
        case snapping(CGPoint)
        case moving(CGPoint)
        case swiping(CGPoint, CGVector)
    }
    
    var state: State {
        didSet {
            if case .snapping(_) = oldValue, case let .moving(point) = state {
                unsnapView()
                attachView(toPoint: point)
            } else if case .snapping(_) = oldValue, case let .swiping(origin, direction) = state {
                unsnapView()
                attachView(toPoint: origin)
                pushView(fromPoint: origin, inDirection: direction)
            } else if case .moving(_) = oldValue, case let .moving(point) = state {
                moveView(toPoint: point)
            } else if case .moving(_) = oldValue, case let .snapping(point) = state {
                detachView(toPoint: point)
                snapView(point)
            } else if case .moving(_) = oldValue, case let .swiping(point, direction) = state {
                pushView(fromPoint: point, inDirection: direction)
            } else if case .swiping(_,_) = oldValue, case let .snapping(point) = state {
                unpushView()
                detachView(toPoint: point)
                snapView(point)
            }
        }
    }
    
    class ZLPanGestureRecognizer: UIPanGestureRecognizer {}
    class ZLTapGestureRecognizer: UITapGestureRecognizer {}
    
    static fileprivate let anchorViewWidth = CGFloat(1000)
    fileprivate var anchorView = UIView(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000))
    
    fileprivate var snapBehavior: UISnapBehavior!
    fileprivate var viewToAnchorViewAttachmentBehavior: UIAttachmentBehavior!
    fileprivate var anchorViewToPointAttachmentBehavior: UIAttachmentBehavior!
    fileprivate var pushBehavior: UIPushBehavior!
    
    let view: UIView
    let containerView: UIView
    let miscContainerView: UIView
    let animator: UIDynamicAnimator
    weak var swipeableView: SwipeableView?
    
    deinit {
        if let snapBehavior = snapBehavior {
            animator.removeBehavior(snapBehavior)
        }
        if let viewToAnchorViewAttachmentBehavior = viewToAnchorViewAttachmentBehavior {
            animator.removeBehavior(viewToAnchorViewAttachmentBehavior)
        }
        if let anchorViewToPointAttachmentBehavior = anchorViewToPointAttachmentBehavior {
            animator.removeBehavior(anchorViewToPointAttachmentBehavior)
        }
        if let pushBehavior = pushBehavior {
            animator.removeBehavior(pushBehavior)
        }
        
        for gestureRecognizer in view.gestureRecognizers! {
            if gestureRecognizer.isKind(of: ZLPanGestureRecognizer.classForCoder()) {
                view.removeGestureRecognizer(gestureRecognizer)
            }
        }
        
        anchorView.removeFromSuperview()
        view.removeFromSuperview()
    }
    
    init(view: UIView, containerView: UIView, index: Int, miscContainerView: UIView, animator: UIDynamicAnimator, swipeableView: SwipeableView)
    {
        self.view = view
        self.containerView = containerView
        self.miscContainerView = miscContainerView
        self.animator = animator
        self.swipeableView = swipeableView
        self.state = ViewManager.defaultSnappingState(view)
        super.init()
        
        view.addGestureRecognizer(ZLPanGestureRecognizer(target: self, action: #selector(ViewManager.handlePan(_:))))
        if swipeableView.didTap != nil {
            self.addTapRecognizer()
        }
        
        anchorView.frame = view.bounds
        miscContainerView.addSubview(anchorView)
        containerView.insertSubview(view, at: index)
    }
    
    static func defaultSnappingState(_ view: UIView) -> State {
        return .snapping(view.convert(view.center, from: view.superview))
    }
    
    func snappingStateAtContainerCenter() -> State {
        guard let swipeableView = swipeableView else {
            return ViewManager.defaultSnappingState(view)
        }
    
        return .snapping(containerView.convert(swipeableView.center, from: swipeableView.superview))
    }
    
    // MARK: Gesture
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let swipeableView = swipeableView else { return }
        
        let location = recognizer.location(in: containerView)
        let translation = recognizer.translation(in: containerView)
        let velocity = recognizer.velocity(in: containerView)
        let movement = Movement(location: location, translation: translation, velocity: velocity)
        
        switch recognizer.state {
        case .began:
            guard case .snapping(_) = state else { return }
            state = .moving(location)
            swipeableView.didStart?(view, location)
        case .changed:
            guard case .moving(_) = state else { return }
            state = .moving(location)
            swipeableView.swiping?(view, location, translation)
        case .ended, .cancelled:
            guard case .moving(_) = state else { return }
            if swipeableView.shouldSwipeView(view, movement, swipeableView) {
                let directionVector = CGVector(translation.normalized * max(velocity.magnitude, swipeableView.minVelocityInPointPerSeconde))
                state = .swiping(location, directionVector)
                swipeableView.swipeView(view, location: location, directionVector: directionVector)
            } else {
                state = snappingStateAtContainerCenter()
                swipeableView.didCancel?(view)
            }
            swipeableView.didEnd?(view, location)
        default:
            break
        }
    }
    
    func addTapRecognizer() {
        for gesture in view.gestureRecognizers ?? [] {
            if let tapGesture = gesture as? ZLTapGestureRecognizer {
                view.removeGestureRecognizer(tapGesture)
            }
            view.addGestureRecognizer(ZLPanGestureRecognizer(target: self, action: #selector(ViewManager.handlePan(_:))))
        }
    }
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let swipeableView = swipeableView, let topView = swipeableView.topView() else { return }
        let location = recognizer.location(in: swipeableView)
        swipeableView.didTap?(topView, location)
    }
    
    // MARK: View handle
    // 悬停
    func snapView(_ point: CGPoint) {
        snapBehavior = UISnapBehavior(item: view, snapTo: point)
        snapBehavior.damping = 0.75
        animator.addBehavior(snapBehavior)
    }
    
    func unsnapView() {
         guard let snapBehavior = snapBehavior else { return }
         animator.removeBehavior(snapBehavior)
    }
    
    func resnapView() {
        if case .snapping(_) = state {
            unsnapView()
            state = snappingStateAtContainerCenter()
        }
    }
    
    // 吸附
    func attachView(toPoint point: CGPoint) {
        anchorView.center = point
        anchorView.backgroundColor = UIColor.blue
        anchorView.isHidden = true
        
        let p = view.center
        viewToAnchorViewAttachmentBehavior = UIAttachmentBehavior(item: view,
                                                                  offsetFromCenter: UIOffset(horizontal: -(p.x-point.x), vertical: -(p.y-point.y)),
                                                                  attachedTo: anchorView,
                                                                  offsetFromCenter: UIOffset.zero)
        viewToAnchorViewAttachmentBehavior.length = 0
        
        anchorViewToPointAttachmentBehavior = UIAttachmentBehavior(item: anchorView, offsetFromCenter: UIOffset.zero, attachedToAnchor: point)
        anchorViewToPointAttachmentBehavior.damping = 100
        anchorViewToPointAttachmentBehavior.length = 0
        
        animator.addBehavior(viewToAnchorViewAttachmentBehavior)
        animator.addBehavior(anchorViewToPointAttachmentBehavior)
    }
    
    
    func moveView(toPoint point: CGPoint) {
        guard let _ = viewToAnchorViewAttachmentBehavior, let toPointBehavior = anchorViewToPointAttachmentBehavior else { return }
        toPointBehavior.anchorPoint = point
    }
    
    func detachView(toPoint point: CGPoint) {
        guard let viewToAnchorViewBehavior = viewToAnchorViewAttachmentBehavior, let anchorViewToPointBehavior = anchorViewToPointAttachmentBehavior else {
            return
        }
        animator.removeBehavior(viewToAnchorViewBehavior)
        animator.removeBehavior(anchorViewToPointBehavior)
    }
    
    func pushView(fromPoint point: CGPoint, inDirection direction: CGVector) {
        guard let _ = viewToAnchorViewAttachmentBehavior,
              let anchorViewToPointBehavior = anchorViewToPointAttachmentBehavior else { return }
        
        animator.removeBehavior(anchorViewToPointBehavior)
        
        pushBehavior = UIPushBehavior(items: [anchorView], mode: .instantaneous)
        pushBehavior.pushDirection = direction
        animator.addBehavior(pushBehavior)
    }
    
    func unpushView() {
        animator.removeBehavior(pushBehavior)
    }
}
