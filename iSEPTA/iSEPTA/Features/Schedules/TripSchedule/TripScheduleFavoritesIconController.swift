//
//  TripScheduleFavoritesIconController.swift
//  iSEPTA
//
//  Created by Mark Broski on 9/3/17.
//  Copyright © 2017 Mark Broski. All rights reserved.
//

import Foundation
import UIKit
import ReSwift
import SeptaSchedule

class TripScheduleFavoritesIconController: FavoritesState_FavoritesWatcherDelegate, ScheduleState_ScheduleRequestWatcherDelegate {

    var favoritesButton: UIButton? {
        didSet {
            setUpTargetAndActionForButton()
        }
    }

    let favoritesWatcher: FavoritesState_FavoritesWatcher?
    let scheduleRequestWatcher: NextToArriveState_ScheduleState_ScheduleRequestWatcher?

    var currentScheduleRequest: ScheduleRequest!
    var currentFavorite: Favorite?

    init(favoritesButton: UIButton) {
        self.favoritesButton = favoritesButton

        favoritesWatcher = FavoritesState_FavoritesWatcher()
        scheduleRequestWatcher = NextToArriveState_ScheduleState_ScheduleRequestWatcher()
    }

    func favoritesState_FavoritesUpdated(favorites _: [Favorite]) {
        currentFavorite = currentScheduleRequest.locateInFavorites()
        updateFavoritesNavBarIcon()
    }

    func scheduleState_ScheduleRequestUpdated(scheduleRequest: ScheduleRequest) {
        currentScheduleRequest = scheduleRequest
        currentFavorite = currentScheduleRequest.locateInFavorites()
        updateFavoritesNavBarIcon()
    }

    func setUpTargetAndActionForButton() {
        favoritesButton?.addTarget(self, action: #selector(NextToArriveFavoritesIconController.didTapFavoritesButton(_:)), for: UIControlEvents.touchUpInside)
    }

    @IBAction func didTapFavoritesButton(_: UIButton) {
        if let currentFavorite = currentFavorite {
            let action = EditFavorite(favorite: currentFavorite)
            store.dispatch(action)
        } else {
            guard let newFavorite = currentScheduleRequest.convertedToFavorite() else { return }
            let action = AddFavorite(favorite: newFavorite)
            store.dispatch(action)
        }
    }

    func updateFavoritesNavBarIcon() {
        let image: UIImage
        if let _ = currentFavorite {
            image = SeptaImages.favoritesEnabled
        } else {
            image = SeptaImages.favoritesNotEnabled
        }
        favoritesButton?.setImage(image, for: UIControlState.normal)
    }
}
