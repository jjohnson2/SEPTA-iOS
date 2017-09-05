// Septa. 2017

import UIKit
import SeptaSchedule
import ReSwift

class SelectRouteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SearchModalHeaderDelegate, UpdateableFromViewModel, IdentifiableController {
    func animatedLayoutNeeded(block _: @escaping (() -> Void), completion _: @escaping (() -> Void)) {
    }

    func layoutNeeded() {
    }

    func updateActivityIndicator(animating _: Bool) {
    }

    func displayErrorMessage(message: String, shouldDismissAfterDisplay: Bool = false) {
        UIAlert.presentOKAlertFrom(viewController: self, withTitle: "Select Routes", message: message)
        if shouldDismissAfterDisplay {
            store.dispatch(DismissModal(navigationController: .schedules, description: "Dismissing after error"))
        }
    }

    @IBOutlet var viewModel: RoutesViewModel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    static var viewController: ViewController = .routesViewController
    let routeCellId = "routeCell"
    @IBOutlet weak var searchTextBox: UITextField!

    func dismissModal() {
        let navigationController = store.state.navigationState.activeNavigationController
        let dismissAction = DismissModal(navigationController: navigationController, description: "Route should be dismissed")
        store.dispatch(dismissAction)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return viewModel.numberOfRows()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: routeCellId, for: indexPath) as? RouteTableViewCell else { return UITableViewCell() }

        viewModel.configureDisplayable(cell, atRow: indexPath.row)
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.rowSelected(row: indexPath.row)
    }

    func viewModelUpdated() {
        guard let tableView = tableView else { return }
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "embedHeader" {
            if let headerViewController = segue.destination as? SearchRoutesModalHeaderViewController {
                headerViewController.delegate = self
                headerViewController.textFieldDelegate = viewModel
            }
        }
    }

    deinit {
    }
}
