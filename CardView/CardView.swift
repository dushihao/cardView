//
//  CardView.swift
//  CardView
//
//  Created by YYKJ on 2020/10/28.
//  Copyright © 2020 YYKJ. All rights reserved.
//

import Foundation
import UIKit

class CardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowOffset = CGSize(width: 0, height: 1.5)
        layer.shadowRadius = 4.0
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        
        layer.cornerRadius = 10.0
    }
}
