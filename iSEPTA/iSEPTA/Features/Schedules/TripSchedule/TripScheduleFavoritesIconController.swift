//
//  TripScheduleFavoritesIconController.swift
//  iSEPTA
//
//  Created by Mark Broski on 9/3/17.
//  Copyright © 2017 Mark Broski. All rights reserved.
//

import Foundation
import UIKit
import ReSwift
import SeptaSchedule

class TripScheduleFavoritesIconController: BaseFavoritesIconController {

    override func subscribe() {
        store.subscribe(self) {
            $0.select { $0.scheduleState.scheduleRequest }.skipRepeats { $0 == $1 }
        }
    }
}
