//
//  NextToArriveButtonView.swift
//  iSEPTA
//
//  Created by Mark Broski on 9/1/17.
//  Copyright © 2017 Mark Broski. All rights reserved.
//

import Foundation

import UIKit

class NextToArriveButtonView: UIButton {
    override func draw(_ rect: CGRect) {
        SeptaDraw.drawSchedulesJumpToNextToArrive(frame: rect)
    }
}
