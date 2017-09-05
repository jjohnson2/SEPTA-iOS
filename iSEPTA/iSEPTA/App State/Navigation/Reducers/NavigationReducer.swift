// Septa. 2017

import Foundation
import ReSwift

struct NavigationReducer {
    static func main(action: Action, state: NavigationState?) -> NavigationState {

        if let state = state {
            guard let action = action as? NavigationAction else { return state }

            return reduceNavigationActions(action: action, state: state)

        } else {
            return NavigationState()
        }
    }

    static func reduceNavigationActions(action: NavigationAction, state: NavigationState) -> NavigationState {
        var appStackState = state.appStackState
        var activeNavigationController = state.activeNavigationController
        switch action {
        case let action as InitializeNavigationState:
            appStackState = reduceInitializeViewAction(action: action, state: appStackState)
        case let action as TransitionView:
            appStackState = reduceTransitionViewAction(action: action, state: appStackState)
        case let action as SwitchTabs:
            activeNavigationController = action.activeNavigationController
        case let action as PresentModal:
            appStackState = reducePresentModalAction(action: action, state: appStackState)
        case let action as DismissModal:
            appStackState = reduceDismissModalAction(action: action, state: appStackState)
        case let action as PushViewController:
            appStackState = reducePushViewControllerAction(action: action, state: appStackState)
        case let action as UserPoppedViewController:
            appStackState = reduceUserPoppedViewControllerAction(action: action, state: appStackState)

        default:
            return state
        }

        return NavigationState(appStackState: appStackState, activeNavigationController: activeNavigationController)
    }

    static func reduceInitializeViewAction(action: InitializeNavigationState, state: AppStackState) -> AppStackState {
        var newState = state
        newState[action.navigationController] = action.navigationStackState
        return newState
    }

    static func reduceTransitionViewAction(action: TransitionView, state: AppStackState) -> AppStackState {
        var newState = state
        var navigationStackState = state[action.navigationController] ?? NavigationStackState()
        var viewControllers = navigationStackState.viewControllers ?? [ViewController]()
        var modalViewController = navigationStackState.modalViewController
        switch action.viewTransitionType {
        case .push:
            guard let viewController = action.viewController else { break }
            viewControllers.append(viewController)
        case .pop:
            viewControllers.removeLast()
        case .presentModal:
            modalViewController = action.viewController
        case .dismissModal:
            modalViewController = nil
        }
        navigationStackState = NavigationStackState(viewControllers: viewControllers, modalViewController: modalViewController)
        newState[action.navigationController] = navigationStackState
        return newState
    }

    static func reducePresentModalAction(action: PresentModal, state: AppStackState) -> AppStackState {
        var newState = state
        let navigationController = store.state.navigationState.activeNavigationController
        var navigationStackState = state[navigationController] ?? NavigationStackState()
        let viewControllers = navigationStackState.viewControllers ?? [ViewController]()

        navigationStackState = NavigationStackState(viewControllers: viewControllers, modalViewController: action.viewController)
        newState[navigationController] = navigationStackState
        return newState
    }

    static func reduceDismissModalAction(action _: DismissModal, state: AppStackState) -> AppStackState {
        var newState = state
        let navigationController = store.state.navigationState.activeNavigationController
        var navigationStackState = state[navigationController] ?? NavigationStackState()
        let viewControllers = navigationStackState.viewControllers ?? [ViewController]()

        navigationStackState = NavigationStackState(viewControllers: viewControllers, modalViewController: nil)
        newState[navigationController] = navigationStackState
        return newState
    }

    static func reducePushViewControllerAction(action: PushViewController, state: AppStackState) -> AppStackState {
        var newState = state
        let navigationController = store.state.navigationState.activeNavigationController
        var navigationStackState = newState[navigationController] ?? NavigationStackState()
        var viewControllers = navigationStackState.viewControllers ?? [ViewController]()
        viewControllers.append(action.viewController)
        navigationStackState = NavigationStackState(viewControllers: viewControllers, modalViewController: nil)
        newState[navigationController] = navigationStackState
        return newState
    }

    static func reduceUserPoppedViewControllerAction(action _: UserPoppedViewController, state: AppStackState) -> AppStackState {
        var newState = state
        let navigationController = store.state.navigationState.activeNavigationController
        var navigationStackState = newState[navigationController] ?? NavigationStackState()
        var viewControllers = navigationStackState.viewControllers ?? [ViewController]()
        viewControllers.removeLast()
        navigationStackState = NavigationStackState(viewControllers: viewControllers, modalViewController: nil)
        newState[navigationController] = navigationStackState
        return newState
    }
}
