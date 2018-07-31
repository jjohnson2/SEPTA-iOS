//
//  CustomPushNotificationsTimeframeView.swift
//  iSEPTA
//
//  Created by Mark Broski on 7/27/18.
//  Copyright © 2018 Mark Broski. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class TimeframeView: UIView {
    @IBOutlet var timeframeLabel: UILabel! {
        didSet {
            guard let text = timeframeLabel.text else { return }
            setTimeFrameLabelText(text: text)
        }
    }

    func setTimeFrameLabelText(text: String) {
        timeframeLabel.attributedText = text.attributed(
            fontSize: 14,
            fontWeight: .bold,
            textColor: SeptaColor.black87,
            alignment: .left,
            kerning: 0.1,
            lineHeight: 24
        )
    }

    @IBOutlet var centeringView: UIView! {
        didSet {
            centeringView.backgroundColor = UIColor.clear
        }
    }

    @IBOutlet var dividerView: UIView! {
        didSet {
            dividerView.backgroundColor = SeptaColor.gray_198
        }
    }

    @IBOutlet var startOfDay: XibView!
    @IBOutlet var endOfDay: XibView!

    func setTimeFrameIndex(index: Int) {
        setTimeFrameLabelText(text: "Timeframe \(index + 1)")
        guard let startView = startOfDay.contentView as? TimeframeBoundaryView,
            let endView = endOfDay.contentView as? TimeframeBoundaryView else { return }
        startView.setHeadingLabel(text: "Start:")
        startView.subscriptonTarget = { $0.preferenceState.pushNotificationPreferenceState.notificationTimeWindows[index].startMinute }
        startView.actionTarget = { date in
            guard let minutesSinceMidnight = MinutesSinceMidnight(date: date) else { return }
            let block: (UserPreferenceState) -> UserPreferenceState = {
                var newState = $0
                newState.pushNotificationPreferenceState.notificationTimeWindows[0].startMinute = minutesSinceMidnight
                return newState
            }
            let action = UpdatePushNotificationTimeframe(block: block)
            store.dispatch(action)
        }
        endView.setHeadingLabel(text: "Until:")
        endView.subscriptonTarget =
            { $0.preferenceState.pushNotificationPreferenceState.notificationTimeWindows[index].endMinute }
        endView.actionTarget = { date in
            guard let minutesSinceMidnight = MinutesSinceMidnight(date: date) else { return }
            let block: (UserPreferenceState) -> UserPreferenceState = {
                var newState = $0
                newState.pushNotificationPreferenceState.notificationTimeWindows[0].endMinute = minutesSinceMidnight
                return newState
            }
            let action = UpdatePushNotificationTimeframe(block: block)
            store.dispatch(action)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 75)
    }
}
