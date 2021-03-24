//
//  SwipeableView.swift
//  CardView
//
//  Created by YYKJ on 2020/10/20.
//  Copyright © 2020 YYKJ. All rights reserved.
//

import UIKit

// data source
public typealias NextViewHandler = () -> UIView?
public typealias PreviousViewHandler = () -> UIView?

// customization
public typealias AnimateViewHandler = (_ view: UIView, _ index: Int, _ views: [UIView], _ swipeableView: SwipeableView) -> ()
public typealias InterpretDirectionHandler = (_ topView: UIView, _ direction: Direction, _ views: [UIView], _ swipeableView: SwipeableView) -> (CGPoint, CGVector)
public typealias ShouldSwipeHandler = (_ view: UIView, _ moveMent: Movement, _ swipeableView: SwipeableView) -> Bool

// delegates
public typealias DidStartHandler = (_ view: UIView, _ atLocation: CGPoint) -> ()
public typealias SwipingHandler = (_ view: UIView, _ atLocation: CGPoint, _ translatin: CGPoint) -> ()
public typealias DidEndHandler = (_ view: UIView, _ atLoaction: CGPoint) -> ()
public typealias DidSwipeHandler = (_ view: UIView, _ inDirection:Direction, _ directionVector: CGVector) -> ()
public typealias DidCancelHandler = (_ view: UIView) -> ()
public typealias DidTap = (_ view: UIView, _ atLocation: CGPoint) -> ()
public typealias DidDisappear = (_ view: UIView) -> ()

public struct Movement {
    public let location: CGPoint
    public let translation: CGPoint
    public let velocity: CGPoint
}

class ContainerView: UIView {}
class MiscContrainerView: UIView {}

open class SwipeableView: UIView {
    
    var numberOfActiveView = UInt(4)
    var previousView: PreviousViewHandler?
    var nextView: NextViewHandler? {
        didSet { loadViews() }
    }
    
    var history = [UIView]()
    var numberOfHistoryItem = UInt(10)
    
    // MARK: Customizable behavior
    var angle = CGFloat(1.0)
    var minTranslationInPercent = CGFloat(0.25)
    var minVelocityInPointPerSeconde = CGFloat(750)
    var allowedDirection = Direction.Horizontal
    var onlySwipeTopCard = false
    
    open var animateView = SwipeableView.defaultAnimateViewHandler()
    open var interpretDirection = SwipeableView.defaultInterpretDirectionHandler()
    open var shouldSwipeView = SwipeableView.defaultShouldSwipeViewHandler()
    
    // MARK: delegates
    open var didStart: DidStartHandler?
    open var swiping: SwipingHandler?
    open var didEnd: DidEndHandler?
    open var didSwipe: DidSwipeHandler?
    open var didCancel: DidCancelHandler?
    open var didTap: DidTap? {
        didSet {
            guard didTap != nil else { return }
            // Update all viewManagers to listen for taps
            viewManagers.forEach { view, viewManager in
                viewManager.addTapRecognizer()
            }
        }
    }
    open var didDisappear: DidDisappear?
    
    var containerView = ContainerView()
    var miscContainerView = MiscContrainerView()
    var animator: UIDynamicAnimator!
    var viewManagers = [UIView: ViewManager]()
    var scheduler = Scheduler()
    
    
    deinit {
         nextView = nil

         didStart = nil
         swiping = nil
         didEnd = nil
         didSwipe = nil
         didCancel = nil
         didDisappear = nil
    }
    
    // MARK: Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        addSubview(containerView)
        addSubview(miscContainerView)
        animator = UIDynamicAnimator(referenceView: self)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = bounds
        for viewManager in viewManagers.values {
            viewManager.resnapView()
        }
    }
    
    // MARK: Public APIs
    func loadViews() {
        for _ in UInt(activeViews().count) ..< numberOfActiveView {
            if let nextView = nextView?() {
                insert(nextView, AtIndex: 0)
            }
        }
        updateViews()
    }
    
    func activeViews() -> [UIView] {
        return allViews().filter { (view) -> Bool in
            guard let viewManager = viewManagers[view] else { return false }
            if case .swiping(_, _) = viewManager.state {
                return false
            }
            return true
        }.reversed()
    }
    
    func topView() -> UIView? {
        return activeViews().first
    }

    func rewind() {
        var viewToBeRewinded: UIView?
        if let lastSwipedView = history.popLast() {
            viewToBeRewinded = lastSwipedView
        } else if let view = previousView?() {
            viewToBeRewinded = view
        }
        
        guard let view = viewToBeRewinded else { return }
        
        if UInt(activeViews().count) == numberOfActiveView && activeViews().first != nil {
            remove(activeViews().last!)
        }
        insert(view, AtIndex: allViews().count)
        updateViews()
    }
    
    func discardTopCard() {
        guard let topView = topView() else { return }
        remove(topView)
        loadViews()
    }
    
    func discardViews() {
        for view in allViews() {
            remove(view)
        }
    }
    
    func swipeTopView(inDirection direction: Direction) {
        guard let topView = topView() else { return }
        let (location, directionVector) = interpretDirection(topView, direction, activeViews(), self)
        swipeTopView(fromPoint: location, inDirection: directionVector)
    }
    
    func swipeTopView(fromPoint location: CGPoint, inDirection directinoVector: CGVector) {
        guard let topView = topView(), let topViewManager = viewManagers[topView] else {
            return
        }
        
        topViewManager.state = .swiping(location, directinoVector)
        swipeView(topView, location: location, directionVector: directinoVector)
    }
    
    // MARK: Private APIs
    func allViews() -> [UIView] {
        return containerView.subviews
    }
    
    func insert(_ view: UIView, AtIndex index: Int) {
        guard !allViews().contains(view) else {
            guard let viewManager = viewManagers[view] else { return }
            viewManager.state = viewManager.snappingStateAtContainerCenter()
            return
        }
        
        let viewManager = ViewManager(view: view, containerView: containerView, index: index, miscContainerView: miscContainerView, animator: animator, swipeableView: self)
        viewManagers[view] = viewManager
    }
    
    func remove(_ view: UIView) {
        guard allViews().contains(view) else { return }
        
        viewManagers.removeValue(forKey: view)
        self.didDisappear?(view)
    }
    
    func updateViews() {
        let activeViews = self.activeViews()
        let inactiveViews = allViews().removeObjectsInArray(activeViews)
        for view in inactiveViews {
            view.isUserInteractionEnabled = false
        }
        
        guard let gestureRecognizers = activeViews.first?.gestureRecognizers, gestureRecognizers.filter({ (gestureRecognizer) -> Bool in
            gestureRecognizer.state != .possible
        }).count == 0 else {
            return
        }
        
        for i in 0 ..< activeViews.count {
            let view = activeViews[i]
            view.isUserInteractionEnabled = onlySwipeTopCard ? i==0 : true
            let shouldBeHidden = i >= Int(numberOfActiveView)
            view.isHidden = shouldBeHidden
            guard !shouldBeHidden else { continue }
            animateView(view, i, activeViews, self)
        }
    }
    
    func swipeView(_ view: UIView, location: CGPoint, directionVector:CGVector) {
        let direction = Direction.fromPoint(CGPoint(x: directionVector.dx, y: directionVector.dy))
        scheduleToBeRemoved(view) { (aView) -> Bool in
            !self.containerView.convert(aView.frame, to: nil).intersects(UIScreen.main.bounds)
        }
        didSwipe?(view, direction, directionVector)
        loadViews()
    }
    
    func scheduleToBeRemoved(_ view:UIView, withPredicate predicate: @escaping (UIView) -> Bool) {
        guard allViews().contains(view) else { return }
        
        history.append(view)
        if UInt(history.count) > numberOfHistoryItem {
            history.removeFirst()
        }
        
        scheduler.scheduleRepeatedly(interval: 0.3) { () -> Void in
            self.allViews().removeObjectsInArray(self.activeViews()).filter({view in predicate(view)}).forEach({view in self.remove(view)})
        } endCondition: { () -> Bool in
            return self.activeViews().count == self.allViews().count
        }
    }
}

// Mark: - Default behaviors
extension SwipeableView {
    static func defaultAnimateViewHandler() -> AnimateViewHandler {
        func toRadian(_ degree: CGFloat) -> CGFloat {
            return degree * CGFloat(Double.pi / 180)
        }
        
        func rotateView(_ view: UIView,
                        forDegree degree: CGFloat,
                        duration: TimeInterval,
                        offsetFromCenter offset: CGPoint,
                        translation: CGPoint,
                        swipeableView: SwipeableView,
                        completion: ((Bool) -> ())? = nil)
        {
            UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
                view.center = swipeableView.convert(swipeableView.center, from: swipeableView.superview)
                var transform = CGAffineTransform(translationX: offset.x, y: offset.y)
                transform = transform.rotated(by: toRadian(degree))
                transform = transform.translatedBy(x: -offset.x, y: -offset.y)
                view.transform = transform
            }, completion: completion)
        }
        
        func rotateAndTranslateView(_ view: UIView,
                                    forDegree degree: CGFloat,
                                    translation: CGPoint,
                                    duration: TimeInterval,
                                    offsetFromCenter offset: CGPoint,
                                    swipeableView: SwipeableView)
        {
            UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
                view.center = swipeableView.convert(swipeableView.center, from: swipeableView.superview)
                var transform = CGAffineTransform(translationX: offset.x, y: offset.y)
                transform = transform.rotated(by: toRadian(degree))
                transform = transform.translatedBy(x: -offset.x, y: -offset.y)
                transform = transform.translatedBy(x: translation.x, y: translation.y)
                view.transform = transform
            }, completion: nil)
        }
        
        return { (view: UIView, index: Int, views: [UIView], swipeableView: SwipeableView) in
            let degree = CGFloat(sin(0.5*Double(index)))
            let duration = 0.4
            let offset = CGPoint(x: 0, y: swipeableView.bounds.height * 0.3)
            let translation = CGPoint(x: 10*degree, y: CGFloat(-10*index)) // 5 * (3-index)
            rotateAndTranslateView(view, forDegree: degree, translation: translation, duration: duration, offsetFromCenter: offset, swipeableView: swipeableView)
//            switch index  {
//            case 0:
//            case 1:
//                rotateAndTranslateView(view, forDegree: degree, translation:translation, duration: duration, offsetFromCenter: offset, swipeableView: swipeableView)
//            case 2:
//                rotateAndTranslateView(view, forDegree: -degree,  translation: translation,duration: duration, offsetFromCenter: offset, swipeableView: swipeableView)
//            default:
//                rotateAndTranslateView(view, forDegree: 0,  translation: translation,duration: duration, offsetFromCenter: offset, swipeableView: swipeableView)
//            }
        }
    }
    
    static func defaultInterpretDirectionHandler() -> InterpretDirectionHandler {
        return { (_ topView: UIView, _ direction: Direction, _ views: [UIView], _ swipeableView: SwipeableView) in
            let programmaSwipeVelocity = CGFloat(1000)
            let location = CGPoint(x: topView.center.x, y: topView.center.y * 0.7)
            let directionVector: CGVector!
            
            switch direction {
            case .Left:
                directionVector = CGVector(dx: -programmaSwipeVelocity, dy: 0)
            case .Right:
                directionVector = CGVector(dx: programmaSwipeVelocity, dy: 0)
            case .Up:
                directionVector = CGVector(dx: 0, dy: -programmaSwipeVelocity)
            case .Down:
                directionVector = CGVector(dx: 0, dy: programmaSwipeVelocity)
            default:
                directionVector = CGVector(dx: 0, dy: 0)
            }
            
            return (location, directionVector)
        }
    }
    
    static func defaultShouldSwipeViewHandler() -> ShouldSwipeHandler {
        return { (_ view: UIView, _ movement: Movement, _ swipeableView: SwipeableView) in
            let translation = movement.translation
            let velocity = movement.velocity
            let bounds = swipeableView.bounds
            let minTranslationInPercent = swipeableView.minTranslationInPercent
            let minVelocityInPointPerSecond = swipeableView.minVelocityInPointPerSeconde
            let allowedDirection = swipeableView.allowedDirection
            
            let areInSameDirection = CGPoint.areInSameDirection(translation, velocity)
            let direction = Direction.fromPoint(translation)
            let isDirectionAllowed = direction.intersection(allowedDirection) != .None
            let isTranslationLargeEnough = abs(translation.x) > minTranslationInPercent * bounds.width || abs(translation.y) > minTranslationInPercent * bounds.height
            let isVelocityLargeEnough = velocity.magnitude > minVelocityInPointPerSecond
            
            return areInSameDirection && isDirectionAllowed && (isTranslationLargeEnough || isVelocityLargeEnough)
        }
    }
}

// MARK: - Helper extensions
public func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}

extension CGPoint {
    init(_ vector: CGVector) {
        self.init(x: vector.dx, y: vector.dy)
    }
    
    var normalized: CGPoint {
        return CGPoint(x: x/magnitude, y: y/magnitude)
    }
    
    var magnitude: CGFloat {
        return CGFloat(sqrtf(powf(Float(x), 2) + powf(Float(y), 2)))
    }
    
    static func areInSameDirection(_ p1: CGPoint, _ p2: CGPoint) -> Bool {
        func signSum(_ n: CGFloat) -> Int {
            return (n < 0.0) ? -1 : ((n > 0.0 ? 1 : 0))
        }
        
        return signSum(p1.x) == signSum(p2.x) && signSum(p1.y) == signSum(p2.y)
    }
}

extension CGVector {
    init(_ point: CGPoint) {
        self.init(dx: point.x, dy: point.y)
    }
}

extension Array where Element: Equatable {
    func removeObjectsInArray(_ array: [Element]) -> [Element] {
        Array(self).filter { (element) -> Bool in
            !array.contains(element)
        }
    }
}
