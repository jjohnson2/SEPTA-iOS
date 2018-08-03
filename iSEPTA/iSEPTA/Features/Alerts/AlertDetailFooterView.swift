//
//  AlertDetailFooterView.swift
//  iSEPTA
//
//  Created by Mark Broski on 8/1/18.
//  Copyright © 2018 Mark Broski. All rights reserved.
//

import Foundation
import ReSwift
import SeptaSchedule
import UIKit

class AlertDetailFooterView: UIView, StoreSubscriber {
    typealias StoreSubscriberStateType = [PushNotificationRoute]

    var pushNotificationRoute: PushNotificationRoute? {
        didSet {
            store.subscribe(self) {
                $0.select { $0.preferenceState.pushNotificationPreferenceState.routeIds }
            }
        }
    }

    @IBAction func toggleNotificationsValueChanged(_ sender: UISwitch) {
        guard let route = pushNotificationRoute else { return }
        guard let viewController = UIResponder.parentViewController(forView: self) else { return }
        DispatchQueue.main.async {
            if sender.isOn {
                store.dispatch(AddPushNotificationRoute(route: route, viewController: viewController))
            } else {
                store.dispatch(RemovePushNotificationRoute(routes: [route], viewController: viewController))
            }
        }
    }

    @IBAction func userTappedOnViewNotificationPreferences(_: Any) {
        store.dispatch(SwitchTabs(activeNavigationController: .more, description: "User wants to view preferences"))
        let navigationStackState = NavigationStackState(viewControllers: [.moreViewController, .managePushNotficationsController], modalViewController: nil)
        let action = InitializeNavigationState(navigationController: .more, navigationStackState: navigationStackState, description: "Deep Linking into More")
        store.dispatch(action)
    }

    func newState(state: StoreSubscriberStateType) {
        guard let route = pushNotificationRoute else { return }
        if let _ = state.first(where: { $0.routeId == route.routeId }) {
            pushNotificationToggleView.isOn = true
        } else {
            pushNotificationToggleView.isOn = false
        }
    }

    deinit {
        store.unsubscribe(self)
    }

    @IBOutlet var pushNotificationToggleView: UISwitch!

    @IBOutlet var subscribeLabel: UILabel! {
        didSet {
            guard let text = subscribeLabel.text else { return }
            subscribeLabel.attributedText = text.attributed(
                fontSize: 14,
                fontWeight: .bold
            )
            subscribeLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 93
            subscribeLabel.setNeedsLayout()
        }
    }

    @IBOutlet var dividerLabel: UIView! {
        didSet {
            dividerLabel.backgroundColor = SeptaColor.gray_135
        }
    }

    @IBOutlet var viewPreferencesButton: UIButton! {
        didSet {
            guard let text = viewPreferencesButton.titleLabel?.text else { return }
            let attributedText = text.attributed(
                fontSize: 12,
                fontWeight: .regular,
                textColor: SeptaColor.blue_20_75_136,
                alignment: .left,
                kerning: 0.2,
                lineHeight: nil
            )
            viewPreferencesButton.setAttributedTitle(attributedText, for: .normal)
        }
    }

    @IBOutlet var viewPreferencesLabel: UILabel! {
        didSet {
            guard let text = viewPreferencesLabel.text else { return }
            viewPreferencesLabel.attributedText = text.attributed(
                fontSize: 12,
                fontWeight: .bold,
                textColor: SeptaColor.blue_20_75_136,
                alignment: .left,
                kerning: 0.2,
                lineHeight: nil
            )
        }
    }
}
