//
//  Scheduler.swift
//  CardView
//
//  Created by YYKJ on 2020/10/20.
//  Copyright © 2020 YYKJ. All rights reserved.
//

import Foundation
import UIKit

class Scheduler : NSObject {
    
    typealias Action = () -> Void
    typealias EndCondition = () -> Bool
    
    var timer: Timer?
    var action: Action?
    var endCondition: EndCondition?
    
    func scheduleRepeatedly(interval: TimeInterval, _ action: @escaping Action, endCondition: @escaping EndCondition) {
        guard timer == nil && interval > 0 else { return }
        self.action = action
        self.endCondition = endCondition
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(doAction(_:)), userInfo: nil, repeats: true)
    }
    
    @objc func doAction(_ timer: Timer) {
        guard let action = action, let endCondition = endCondition, !endCondition() else {
            timer.invalidate()
            self.timer = nil
            self.action = nil
            self.endCondition = nil
            return
        }
        action()
    }
}
