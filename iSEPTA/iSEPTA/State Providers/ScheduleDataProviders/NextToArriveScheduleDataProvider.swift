//
//  NextToArriveScheduleProvider.swift
//  iSEPTA
//
//  Created by Mark Broski on 9/4/17.
//  Copyright © 2017 Mark Broski. All rights reserved.
//

import Foundation
import ReSwift
import SeptaSchedule

class NextToArriveScheduleDataProvider: BaseScheduleDataProvider {

    static let sharedInstance = NextToArriveScheduleDataProvider()

    init() {
        super.init(targetForScheduleAction: .nextToArrive)
    }

    override func subscribe() {
        store.subscribe(self) {
            $0.select { $0.nextToArriveState.scheduleState.scheduleRequest }.skipRepeats { $0 == $1 }
        }
    }

    override func processSelectedTransitMode(scheduleRequest: ScheduleRequest) {
        if scheduleRequest.transitMode == .rail && scheduleRequest.selectedStart == nil {
            let action = LoadAllRailRoutes()
            store.dispatch(action)
        } else {
            retrieveAvailableRoutes(scheduleRequest: scheduleRequest)
        }
    }

    deinit {
        print("Next to arrive schedule data provider will vanish")
    }
}
