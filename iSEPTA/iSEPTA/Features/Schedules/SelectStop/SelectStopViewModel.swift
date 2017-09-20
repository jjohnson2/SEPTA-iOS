// Septa. 2017

import Foundation
import SeptaSchedule
import ReSwift

import UIKit

class SelectStopViewModel: NSObject, StoreSubscriber {
    typealias StoreSubscriberStateType = ScheduleStopState
    var targetForScheduleAction: TargetForScheduleAction! { return store.state.targetForScheduleActions() }
    @IBOutlet weak var selectStopViewController: UpdateableFromViewModel?
    var filterString = ""
    let cellId = "stopCell"

    var stopToSelect: StopToSelect = .starts {
        didSet {
            subscribe()
        }
    }

    var allStops: [Stop]? {
        didSet {
            guard let allStops = allStops else { return }
            allFilterableStops = allStops.map {
                FilterableStop(stop: $0)
            }
        }
    }

    fileprivate var allFilterableStops: [FilterableStop]? {
        didSet {
            filteredStops = allFilterableStops
        }
    }

    var filteredStops: [FilterableStop]? {
        didSet {
            guard let filteredStops = filteredStops else { return }
            self.filteredStops = filteredStops.sorted {
                $0.sortString < $1.sortString
            }
            selectStopViewController?.viewModelUpdated()
        }
    }

    func subscribe() {
        if targetForScheduleAction == .schedules {
            if stopToSelect == .starts {
                store.subscribe(self) {
                    $0.select {
                        $0.scheduleState.scheduleData.availableStarts
                    }.skipRepeats { $0 == $1 }
                }
            } else {
                store.subscribe(self) {
                    $0.select {
                        $0.scheduleState.scheduleData.availableStops
                    }.skipRepeats { $0 == $1 }
                }
            }
        } else if targetForScheduleAction == .nextToArrive {
            if stopToSelect == .starts {
                store.subscribe(self) {
                    $0.select {
                        $0.nextToArriveState.scheduleState.scheduleData.availableStarts
                    }.skipRepeats { $0 == $1 }
                }
            } else {
                store.subscribe(self) {
                    $0.select {
                        $0.nextToArriveState.scheduleState.scheduleData.availableStops
                    }.skipRepeats { $0 == $1 }
                }
            }
        }
    }

    func newState(state: StoreSubscriberStateType) {
        allStops = state.stops
        if state.updateMode == .loadValues && state.stops.count == 0 {
            selectStopViewController?.displayErrorMessage(message: SeptaString.NoStopsAvailable, shouldDismissAfterDisplay: true)
            selectStopViewController?.updateActivityIndicator(animating: false)
        } else if state.updateMode == .clearValues {
            selectStopViewController?.updateActivityIndicator(animating: true)
        } else if state.updateMode == .loadValues && state.stops.count > 0 {
            selectStopViewController?.updateActivityIndicator(animating: false)
        }
    }

    deinit {
        store.unsubscribe(self)
    }

    func unsubscribe() {
        store.unsubscribe(self)
    }
}

extension SelectStopViewModel: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return numberOfRows()
    }

    func numberOfRows() -> Int {
        guard let filteredStops = filteredStops else { return 0 }
        return filteredStops.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SelectStopCell else { return UITableViewCell() }

        configureDisplayable(cell, atRow: indexPath.row)
        return cell
    }

    func configureDisplayable(_ displayable: SingleStringDisplayable, atRow row: Int) {
        guard let filteredStops = filteredStops, row < filteredStops.count else { return }
        let stop = filteredStops[row].stop

        displayable.setLabelText(stop.stopName)
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        rowSelected(row: indexPath.row)
    }

    func rowSelected(row: Int) {
        guard let filteredStops = filteredStops, row < filteredStops.count else { return }
        let stop = filteredStops[row].stop
        store.unsubscribe(self)
        if stopToSelect == .starts {
            let action = TripStartSelected(targetForScheduleAction: targetForScheduleAction, selectedStart: stop)
            store.dispatch(action)
        } else {
            let action = TripEndSelected(targetForScheduleAction: targetForScheduleAction, selectedEnd: stop)
            store.dispatch(action)
        }
        let dismissAction = DismissModal(description: "Stop should be dismissed")
        store.dispatch(dismissAction)
    }
}

extension SelectStopViewModel: UITextFieldDelegate {

    func textField(_: UITextField, shouldChangeCharactersIn range: NSRange, replacementString: String) -> Bool {

        guard let allFilterableStops = allFilterableStops, let swiftRange = Range(range, in: filterString) else { return false }
        filterString = filterString.replacingCharacters(in: swiftRange, with: replacementString.lowercased())

        filteredStops = allFilterableStops.filter {
            guard filterString.characters.count > 0 else { return true }

            return $0.filterString.contains(filterString)
        }
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.selectStopViewController?.viewModelUpdated()
        }

        return true
    }
}
