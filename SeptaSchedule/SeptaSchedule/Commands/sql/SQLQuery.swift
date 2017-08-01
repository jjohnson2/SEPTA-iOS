// SEPTA.org, created on 7/31/17.

import Foundation

enum SQLQuery {
    case busStart(routeId: Int, scheduleType: ScheduleType)
    case busEnd(routeId: Int, scheduleType: ScheduleType, startStopId: Int)
    case busTrip(routeId: Int, scheduleType: ScheduleType, startStopId: Int, endStopId: Int)

    var sqlBindings: [[String]] {
        switch self {
        case let .busStart(routeId, scheduleType):
            return [[":route_id", String(routeId)], [":service_id", String(scheduleType.rawValue)]]
        case let .busEnd(routeId, scheduleType, startStopId):
            return [[":route_id", String(routeId)], [":service_id", String(scheduleType.rawValue)], [":start_stop_id", String(startStopId)]]
        case let .busTrip(routeId, scheduleType, startStopId, endStopId):
            return [[":route_id", String(routeId)], [":service_id", String(scheduleType.rawValue)], [":start_stop_id", String(startStopId)], [":end_stop_id", String(endStopId)]]
        }
    }

    var fileName: String {
        switch self {
        case .busStart: return "busStart"
        case .busEnd: return "busEnd"
        case .busTrip: return "busTrip"
        }
    }
}