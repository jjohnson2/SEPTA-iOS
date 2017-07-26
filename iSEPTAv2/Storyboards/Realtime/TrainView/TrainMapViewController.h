//
//  TrainMapViewController.h
//  iSEPTA
//
//  Created by septa on 9/23/13.
//  Copyright (c) 2013 SEPTA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>


// --==  Helper Classes  ==--
#import "CustomFlatBarButton.h"
#import "KMLParser.h"
#import "LineHeaderView.h"

#import "KMLObject.h"
#import "KMLOverlay.h"
#import "KMLOverlayView.h"
// --==  Helper Classes  ==--


#import "TrainRealtimeDataViewController.h"


// --==  PODs  ==--
#import <ECSlidingViewController/ECSlidingViewController.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <AFNetworking/AFNetworking.h>
#import <Reachability/Reachability.h>
#import <ALAlertBanner/ALAlertBanner.h>
// --==  PODs  ==--


// --==  Data Models  ==--
#import "TrainViewObject.h"
#import "TransitViewObject.h"
// - for KML Parsing
#import "RouteData.h"
//#import "mapAnnotation.h"
#import "KMLAnnotation.h"
#import "KMLAnnotationView.h"


// --==  Xibs  ==--
#import "RealtimeVehicleInformationCell.h"


// --==  Common  ==--
#import "GTFSCommon.h"

#import "AppDelegate.h"

#define JSON_REFRESH_RATE 20.0f




@interface TrainMapViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) NSNumber *travelMode;
@property (strong, nonatomic) NSString *routeName;

@property (strong, nonatomic) NSString *backImageName;

@end
