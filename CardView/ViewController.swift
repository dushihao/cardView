//
//  ViewController.swift
//  CardView
//
//  Created by YYKJ on 2020/10/20.
//  Copyright © 2020 YYKJ. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var swipeableView: SwipeableView!
    var colors = ["Turquoise", "Green Sea", "Emerald", "Nephritis", "Peter River", "Belize Hole", "Amethyst", "Wisteria", "Wet Asphalt", "Midnight Blue", "Sun Flower", "Orange", "Carrot", "Pumpkin", "Alizarin", "Pomegranate", "Clouds", "Silver", "Concrete", "Asbestos"]
    var colorIndex = 0
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        swipeableView.nextView = {
            return self.nextCardView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        swipeableView = SwipeableView()
//        swipeableView.backgroundColor = UIColor.red
        view.addSubview(swipeableView)
        stateDelegateHandler()
        
        swipeableView.translatesAutoresizingMaskIntoConstraints = false
        let HFormat = "H:|-50-[swipeableView]-50-|"
        let VFormat = "V:|-120-[swipeableView]-100-|"
        let constraints0 = NSLayoutConstraint.constraints(withVisualFormat: HFormat, options: [], metrics:nil, views: ["swipeableView": swipeableView!])
        let constraints1 = NSLayoutConstraint.constraints(withVisualFormat: VFormat, options: [], metrics:nil, views: ["swipeableView": swipeableView!])
        
        view.addConstraints(constraints0)
        view.addConstraints(constraints1)
    }

    func stateDelegateHandler() {
        swipeableView.didStart = { view, location in
            print("Did start swiping view at location: \(location)")
        }
        
        swipeableView.swiping = {view, location, translation in
            print("Swiping at view location: \(location) translation: \(translation)")
        }
        
        swipeableView.didEnd = {view, location in
            print("Did end swiping view at location: \(location)")
        }
        swipeableView.didSwipe = {view, direction, vector in
            print("Did swipe view in direction: \(direction), vector: \(vector)")
        }
        swipeableView.didCancel = {view in
            print("Did cancel swiping view")
        }
        swipeableView.didTap = {view, location in
            print("Did tap at location \(location)")
        }
        swipeableView.didDisappear = { view in
            print("Did disappear swiping view")
        }
    }
    
    func nextCardView() -> UIView? {
        if colorIndex > colors.count {
            colorIndex = 0
        }
        let cardView =  CardView(frame: swipeableView.bounds)
        cardView.backgroundColor = UIColor.randomColor
        colorIndex += 1
        
        return cardView
    }
    
    func colorForName(_ name: String) -> UIColor {
        let sanitizedName = name.replacingOccurrences(of: " ", with: "")
        let selector = "flat\(sanitizedName)Color"
        return UIColor.perform(Selector(selector)).takeUnretainedValue() as! UIColor
    }
}

extension UIColor {
    static var randomColor: UIColor {
        get
        {
            let red = CGFloat(arc4random()%256)/255.0
            let green = CGFloat(arc4random()%256)/255.0
            let blue = CGFloat(arc4random()%256)/255.0
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        }
    }
}
