// Septa. 2017

import Foundation
import ReSwift
import SeptaSchedule

class UserPreferencesProvider: StoreSubscriber, UserPreferencesProviderProtocol {
    typealias StoreSubscriberStateType = UserPreferenceState

    var currentState: UserPreferenceState?

    static let sharedInstance = UserPreferencesProvider()
    private init() {}

    func subscribe() {
        store.subscribe(self) { subscription in
            subscription.select(self.filterSubscription)
        }
    }

    func filterSubscription(state: AppState) -> UserPreferenceState {
        return state.preferenceState
    }

    private func unsubscribe() {
        store.unsubscribe(self)
    }

    deinit {
        unsubscribe()
    }

    func newState(state: StoreSubscriberStateType) {
        if currentState == nil {
            initializePreferenceStateFromDefaults()
        } else {
            if currentState != state {
                UserPreferencesStatePersister.sharedInstance.persistPreferenceState(state)
                currentState = state
            }
        }
    }

    func initializePreferenceStateFromDefaults() {
        UserDefaultsLoader.sharedInstance.loadDefaults { [weak self] state, _ in
            guard let strongSelf = self
            else { return }
            if let state = state {
                strongSelf.currentState = state
                strongSelf.dispatchStartupActions()
            } else {
                print("There was a problem retrieving defaults")
            }
        }
    }

    func dispatchStartupActions() {
        dispatchPreferencesRetrieved()
        dispatchStartupNavigationController()
        dispatchStartupTransitMode()
    }

    func dispatchPreferencesRetrieved() {
        guard let currentState = currentState else { return }
        let action = PreferencesRetrievedAction(userPreferenceState: currentState)
        store.dispatch(action)
    }

    func dispatchStartupTransitMode() {
        guard let transitMode = currentState?.startupTransitMode else { return }
        let action = TransitModeSelected(transitMode: transitMode, description: "Loading from user defaults")
        store.dispatch(action)
    }

    func dispatchStartupNavigationController() {
        guard let navigationController = currentState?.startupNavigationController else { return }
        let action = SwitchTabs(tabBarItemIndex: navigationController.tabIndex(), description: "Loading From Defaults")
        store.dispatch(action)
    }
}