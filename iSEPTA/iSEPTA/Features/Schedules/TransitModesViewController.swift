// Septa. 2017

import UIKit
import SeptaSchedule
import ReSwift

class TransitModesViewController: UIViewController, StoreSubscriber {
    @IBOutlet weak var transitModeView: UIView!
    @IBOutlet weak var scrollbar: UIScrollView!
    @IBOutlet var transitModesToolbarElements: [TransitModeToolbarView]!
    override func viewDidLoad() {

        view.backgroundColor = UIColor(red: 0.600, green: 0.600, blue: 0.600, alpha: 1.000)
    }

    override func viewWillAppear(_: Bool) {
        guard let navBar = navigationController?.navigationBar else { return }
        navBar.backgroundColor = UIColor.clear
        navBar.shadowImage = UIImage()
        navBar.setBackgroundImage(UIImage(), for: .default)
        store.subscribe(self) { subscription in
            subscription.select(self.filterSubscription)
        }
    }

    @IBAction func toolbarTapped(_ gr: UITapGestureRecognizer) {

        guard !scrollbar.isDragging || !scrollbar.isDecelerating else { return }
        let pt = gr.location(in: gr.view)
        _ = transitModesToolbarElements.map { $0.highlighted = false }
        let hitToolbar = transitModesToolbarElements.filter {

            let contains = $0.frame.contains(pt)
            return contains
        }.first

        hitToolbar?.highlighted = true

        _ = transitModesToolbarElements.map { $0.setNeedsDisplay() }

        let action = ScheduleActions.TransitModeSelected(transitMode: hitToolbar?.transitMode)
        store.dispatch(action)
    }

    typealias StoreSubscriberStateType = NavigationState

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        store.dispatch(SwitchFeatureCompleted(activeFeature: .schedules))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        store.unsubscribe(self)
    }

    func filterSubscription(state: AppState) -> NavigationState {
        return state.navigationState
    }

    func newState(state _: StoreSubscriberStateType) {
    }
}