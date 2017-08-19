// Septa. 2017

import UIKit
import SeptaSchedule
import ReSwift

class SelectSchedulesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UpdateableFromViewModel, IdentifiableController, SchedulesViewModelDelegate {
    @IBOutlet weak var tableViewWrapper: UIView!

    static var viewController: ViewController = .selectSchedules

    @IBOutlet weak var buttonView: UIView!
    @IBOutlet var buttons: [UIButton]!
    @IBAction func ViewSchedulesButtonTapped(_: Any) {
        let action = PushViewController(navigationController: .schedules, viewController: .tripScheduleController, description: "Show Trip Schedule")
        store.dispatch(action)
    }

    @IBAction func resetButtonTapped(_: Any) {
        store.dispatch(ResetSchedule())
    }

    let cellId = "singleStringCell"
    @IBOutlet var tableViewHeader: UIView!
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet var tableViewFooter: UIView!
    var viewModel: SelectSchedulesViewModel!

    override func viewDidLoad() {
        viewModel = SelectSchedulesViewModel(delegate: self)
        view.backgroundColor = SeptaColor.navBarBlue
        tableView.tableFooterView = tableViewFooter
        viewModel.subscribe()
        viewModel.schedulesDelegate = self
        buttonView.isHidden = true
        UIView.addSurroundShadow(toView: tableViewWrapper)
    }

    override func viewWillAppear(_: Bool) {
        guard let navBar = navigationController?.navigationBar else { return }

        navBar.shadowImage = UIImage()
        navBar.setBackgroundImage(UIImage(), for: .default)
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return viewModel.numberOfRows()
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? SingleStringCell else { return UITableViewCell() }

        viewModel.configureDisplayable(cell, atRow: indexPath.row)
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.rowSelected(indexPath.row)
    }

    func tableView(_: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return viewModel.canCellBeSelected(atRow: indexPath.row)
    }

    func viewModelUpdated() {
        tableView.reloadData()
    }

    func formIsComplete(_ isComplete: Bool) {
        buttonView.isHidden = !isComplete
    }

    deinit {
        viewModel.unsubscribe()
    }
}
