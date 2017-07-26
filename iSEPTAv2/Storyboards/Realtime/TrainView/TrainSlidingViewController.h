//
//  TrainSlidingViewController.h
//  iSEPTA
//
//  Created by septa on 9/23/13.
//  Copyright (c) 2013 SEPTA. All rights reserved.
//

#import <UIKit/UIKit.h>


// --==  Helper Class  ==--
#import "CustomFlatBarButton.h"


#import "TrainRealtimeDataViewController.h"
#import "TrainMapViewController.h"


// --==  PODs  ==--
#import <ECSlidingViewController/ECSlidingViewController.h>




@interface TrainSlidingViewController : ECSlidingViewController

@property (strong, nonatomic) NSNumber *travelMode;
@property (strong, nonatomic) NSString *routeName;

@property (strong, nonatomic) NSString *backImageName;

@end
