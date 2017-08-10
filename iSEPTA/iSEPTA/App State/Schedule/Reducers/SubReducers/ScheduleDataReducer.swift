// Septa. 2017

import Foundation
import SeptaSchedule

struct ScheduleDataReducer {

    static func initScheduleData() -> ScheduleData {
        return ScheduleData()
    }

    static func reduceData(action: ScheduleAction, scheduleData: ScheduleData) -> ScheduleData {
        var newScheduleData = scheduleData
        switch action {
        case _ as TransitModeSelected:
            newScheduleData = ScheduleData()
        case let action as DisplayRoutes:
            newScheduleData = reduceDisplayRoutes(action: action, scheduleData: newScheduleData)
        default:
            newScheduleData = scheduleData
        }
        return newScheduleData
    }

    static func reduceDisplayRoutes(action _: DisplayRoutes, scheduleData: ScheduleData) -> ScheduleData {

        return scheduleData
    }
}