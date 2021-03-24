//
//  Direction.swift
//  CardView
//
//  Created by YYKJ on 2020/10/20.
//  Copyright © 2020 YYKJ. All rights reserved.
//

import Foundation
import UIKit

public typealias ZLSwipeableViewDirection = Direction

extension Direction : Equatable {}
public func == (lhs: Direction, rhs: Direction) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public struct Direction : OptionSet, CustomStringConvertible {
    
    public var rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static let None = Direction(rawValue: 0b0000)
    public static let Left = Direction(rawValue: 0b0001)
    public static let Right = Direction(rawValue: 0b0010)
    public static let Up = Direction(rawValue: 0b0100)
    public static let Down = Direction(rawValue: 0b1000)
    public static let Horizontal : Direction = [Left, Right]
    public static let Vertical : Direction = [Up, Down]
    public static let All : Direction = [Horizontal, Vertical]
    
    public var description: String {
        switch self {
        case .None:
            return "None"
        case .Left:
            return "Left"
        case .Right:
            return "Right"
        case .Up:
            return "Up"
        case .Down:
            return "Down"
        case .Horizontal:
            return "Horizontal"
        case .Vertical:
            return "Vertical"
        case .All:
            return "All"
        default:
            return "Unknown"
        }
    }
    
    public static func fromPoint(_ point: CGPoint) -> Direction {
        switch (point.x, point.y) {
        case let (x, y) where abs(x) >= abs(y) && x > 0:
            return .Right
        case let (x, y) where abs(x) >= abs(y) && x < 0:
            return .Left
        case let (x, y) where abs(x) < abs(y) && y < 0:
            return .Up
        case let (x, y) where abs(x) < abs(y) && y > 0:
            return .Down
        case (_, _):
            return .None
        }
    }
}

