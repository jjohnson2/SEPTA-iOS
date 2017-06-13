//
//  TrainMapViewController.m
//  iSEPTA
//
//  Created by septa on 9/23/13.
//  Copyright (c) 2013 SEPTA. All rights reserved.
//

#import "TrainMapViewController.h"

@interface TrainMapViewController ()

@end

@implementation TrainMapViewController
{
    
    NSMutableArray *_tableData;
    NSMutableDictionary *_annotationLookup;
    
    CLLocationManager *_locationManager;
    
    NSOperationQueue *_jsonQueue;
    NSBlockOperation *_jsonOp;
    
    BOOL _reverseSort;
    BOOL _killAllTimers;
    BOOL _stillWaitingOnWebRequest;
    BOOL _locationEnabled;
    
    NSTimer *updateTimer;
//    NSTimer *annotationTimer;
    
    
    // -- for KML Parsing
    KMLParser *kmlParser;
    NSBlockOperation *_kmlOp;
    NSOperationQueue *_mainQueue;
    
    MKMapRect flyTo;
    
    TrainRealtimeDataViewController *_trainDataVC;
    
}



-(void)viewDidLoad
{
    
    [super viewDidLoad];
    
//    [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(popTheVC) userInfo:Nil repeats:NO];
//    return;
    
    _tableData = [[NSMutableArray alloc] init];
    _annotationLookup = [[NSMutableDictionary alloc] init];
    
    _mainQueue = [[NSOperationQueue alloc] init];

    
    // --==
    // --==  Determine title of view  ==--
    // --==
    NSString *title = @"TrainView";
    if ( self.travelMode != nil )
    {
        if ( (GTFSRouteType)[self.travelMode intValue] == kGTFSRouteTypeRail )
        {
            title = @"TrainView";  // No change
        }
        else
        {
            title = @"TransitView";  // If it ain't rail, then it's Transit
        }
    }
    else
    {
        self.travelMode = [NSNumber numberWithInt: kGTFSRouteTypeRail];
    }
    
    
    if ( [self.routeName isEqualToString:@"BSL"] )
    {
        [self loadBannerWithTitle:@"BSL" andSubtitle:@"Vehicle locations along the Broad Street Line are not available."];
    }
    else if ( [self.routeName isEqualToString:@"MFL"] )
    {
        [self loadBannerWithTitle:@"MFL" andSubtitle:@"Vehicle locations along the Market-Frankford Line are not available."];
    }
    else if ( [self.routeName isEqualToString:@"NHSL"] )
    {
        [self loadBannerWithTitle:@"NHSL" andSubtitle:@"Vehicle locations along the Norristown High Speed Line are not available."];
    }
    else if ( (GTFSRouteType)[self.travelMode intValue] == kGTFSRouteTypeTrolley )
    {
        [self loadBannerWithTitle:@"Trolley" andSubtitle:@"Vehicle locations for trolleys are limited while underground."];
    }
    
    
    LineHeaderView *titleView = [[LineHeaderView alloc] initWithFrame:CGRectMake(0, 0, 500, 32) withTitle: title];
    [self.slidingViewController.navigationItem setTitleView:titleView];
    
    
    // --==
    // ==--  Setting up CLLocation Manager
    // --==
    if ( [CLLocationManager locationServicesEnabled] )
    {
        
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
        
        if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        {
            [_locationManager requestWhenInUseAuthorization];
        }
        
        [_locationManager setDistanceFilter: kCLDistanceFilterNone];
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
        [_locationManager startUpdatingLocation];
        
        _locationEnabled = YES;
        
        
        // --==
        // ==--  Display Current Location On MapView Thumbnail  ==--
        // --==
        
        // A little background on span, thanks to http://stackoverflow.com/questions/7381783/mkcoordinatespan-in-meters
        float radiusInMiles = 2.0;
        [self.mapView setRegion: MKCoordinateRegionMakeWithDistance(_locationManager.location.coordinate, [self milesToMetersFor:radiusInMiles*2], [self milesToMetersFor:radiusInMiles*2] ) animated:YES];

        [self.mapView setCenterCoordinate:_locationManager.location.coordinate animated:YES];
        [self.mapView setZoomEnabled:YES];
        [self.mapView setScrollEnabled:YES];
        
        [self.mapView setShowsUserLocation:YES];
        [self.mapView setDelegate:self];
        
    }
    else
    {
        _locationEnabled = NO;
    }
    
    
    
    // --==  Initialize NSOperation Queue
    _jsonQueue = [[NSOperationQueue alloc] init];
    
    _reverseSort = NO;
    _killAllTimers = NO;
    _stillWaitingOnWebRequest = NO;
    
    
    
//    if ( _locationEnabled )
//    {
        // If the network is not reachable, try again in another 20 seconds
        [self getLatestJSONData];       // Grabs the last updated data on the vehciles of the requested route
    
        [self loadKMLInTheBackground];  // Loads the KML for the requested route in the background
//    }
    
    
}


-(void) loadBannerWithTitle:(NSString*)title andSubtitle:(NSString*) subtitle
{
    
//    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
//    appDelegate.window
    return;  // Temporarily disabled while the map issue with Maps is worked out
    
//    ALAlertBanner *_alertBanner = [ALAlertBanner alertBannerForView:self.mapView
//                                               style:ALAlertBannerStyleFailure
//                                            position:ALAlertBannerPositionTop
//                                               title: title
//                                            subtitle: subtitle
//                                         tappedBlock:^(ALAlertBanner *alertBanner)
//                    {
//                        NSLog(@"No realtime data");
//                        [alertBanner hide];
//                    }];
//    
//    NSLog(@"TMVC - _alertBanner show!");
//    
//    NSTimeInterval showTime = 10.0f;
//    [_alertBanner setSecondsToShow: showTime];
//
//    [_alertBanner show];
    
}

-(void) popTheVC
{
//    self.counter++;
    [self.slidingViewController.navigationController popViewControllerAnimated:YES];
}


-(void) viewWillDisappear:(BOOL)animated
{
    
    [super viewWillDisappear:animated];
    
    NSLog(@"TMVC - viewWillDisappear");
    
    [_jsonQueue cancelAllOperations];
    _killAllTimers = YES;
    
    [updateTimer invalidate];
    
    [SVProgressHUD dismiss];
    

    [ALAlertBanner forceHideAllAlertBannersInView:self.view];
    
    
    [self.mapView setDelegate:nil];
    
    
    _jsonQueue = nil;
    _jsonOp = nil;
    
    
    [kmlParser clear];
    kmlParser = nil;

    
    [_locationManager stopUpdatingLocation];
    [_locationManager setDelegate:nil];
    
    
    [super viewDidDisappear:animated];
    
    NSLog(@"TMVC - viewWillDisappear isFinished");
    
}


-(void)viewWillAppear:(BOOL)animated
{
    

    _killAllTimers = NO;
    
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    if (![self.slidingViewController.underRightViewController isKindOfClass:[TrainRealtimeDataViewController class]]) {
        self.slidingViewController.underRightViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Data"];
    }

    _trainDataVC = (TrainRealtimeDataViewController*)self.slidingViewController.underRightViewController;

    CustomFlatBarButton *rightButton = [[CustomFlatBarButton alloc] initWithImageNamed:@"second-menu.png" withTarget:self andWithAction:@selector(slide:)];
    [self.slidingViewController.navigationItem setRightBarButtonItem: rightButton];
    
    
    if ( self.backImageName == nil )
        [self setBackImageName:@"RRL_white.png"];
    
    CustomFlatBarButton *backBarButtonItem = [[CustomFlatBarButton alloc] initWithImageNamed: self.backImageName withTarget:self andWithAction:@selector(backButtonPressed:)];
    self.slidingViewController.navigationItem.leftBarButtonItem = backBarButtonItem;
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    [self.mapView setDelegate:self];
    [super viewWillAppear:animated];

    [_locationManager setDelegate:self];
    [_locationManager startUpdatingLocation];
    
    NSLog(@"TMVC:vWA - Done!");
    
}


- (void)didReceiveMemoryWarning
{
    
    [super didReceiveMemoryWarning];
    
    return;

}


- (void)viewDidUnload
{
    NSLog(@"TMVC - viewDidUnload");
    
    _trainDataVC = nil;
    [self setMapView:nil];
    [super viewDidUnload];
}


-(void) slide:(id) sender
{
    NSLog(@"TMVC:vWA - Slide, you fool.  Slide!");
    
    if ( ![self.slidingViewController underRightShowing] )
        [self.slidingViewController anchorTopViewTo:ECLeft];
    else
        [self.slidingViewController resetTopView];
    
}


-(void) backButtonPressed:(id) sender
{
    [self.slidingViewController.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Custom Methods
-(float) milesToMetersFor: (float) miles
{
    return 1609.344f * miles;
}


#pragma mark - JSON Data
-(void) getLatestJSONData
{
    
    //    NSLog(@"NTVVC - getLatestJSONData");
    
    Reachability *network = [Reachability reachabilityForInternetConnection];
    if ( ![network isReachable] )
    {
        // Disable realtime buttons if no internet connection is available
        [self kickOffAnotherJSONRequest];
        return;
    }
    
    
    if ( _stillWaitingOnWebRequest )  // The attempt here is to avoid asking the web server for data if it hasn't returned anything from the previous request
        return;
    else
        _stillWaitingOnWebRequest = YES;
    
    
    NSString* webStringURL;
    NSString *stringURL;
    GTFSRouteType routeType = (GTFSRouteType)[self.travelMode intValue];

    
    switch (routeType)
    {
        case kGTFSRouteTypeBus:
        case kGTFSRouteTypeTrolley:
            stringURL = [NSString stringWithFormat:@"https://www3.septa.org/hackathon/TransitView/%@", self.routeName];
            webStringURL = [stringURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//            NSLog(@"TMVC - getLatestJSONData (bus) -- api url: %@", webStringURL);
            
            break;
            
        case kGTFSRouteTypeRail:
            
            stringURL = [NSString stringWithFormat:@"https://www3.septa.org/hackathon/TrainView/"];
            webStringURL = [stringURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//            NSLog(@"TMVC - getLatestJSONData (rail) -- api url: %@", webStringURL);
            
            break;
            
        default:
            return;
            break;
    }
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    
    _jsonOp     = [[NSBlockOperation alloc] init];
    
    __weak NSBlockOperation *weakOp = _jsonOp;  // weak reference avoids retain cycle when calling [self processJSONData:...]
    [weakOp addExecutionBlock:^{
        
        NSData *realTimeJSONData = [NSData dataWithContentsOfURL:[NSURL URLWithString:webStringURL] ];
        
        if ( ![weakOp isCancelled] )
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self processJSONData:realTimeJSONData];
            }];
        }
        else
        {
            NSLog(@"TMVC - getLatestJSONData: _jsonOp cancelled");
        }
        
    }];
    
    [_jsonQueue addOperation: _jsonOp];
    
}



-(void) processJSONData:(NSData*) returnedData
{
    
    _stillWaitingOnWebRequest = NO;  // We're no longer waiting on the web request
    [SVProgressHUD dismiss];
    
    if ( returnedData == nil )
        return;
    
    // This method is called once the realtime positioning data has been returned via the API
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData: returnedData options:kNilOptions error:&error];
    NSMutableArray *readData = [[NSMutableArray alloc] init];
    
    if ( error != nil )
        return;  // Something bad happened, so just return.
    
    //    [masterList removeAllObjects];
    GTFSRouteType routeType = (GTFSRouteType)[self.travelMode intValue];
    
    
    // TODO: Only remove annotations where the data has changed
    NSMutableArray *annotationsToRemove = [[self.mapView annotations] mutableCopy];  // Make a mutable copy of the annotation array
    [annotationsToRemove removeObject: [self.mapView userLocation] ];                // Remove the userLocation annotation from the array
    [self.mapView removeAnnotations: annotationsToRemove];                           // All annotations except for the userLocation are now removed
    annotationsToRemove = nil;
    
    
    switch (routeType)
    {
        case kGTFSRouteTypeBus:
        case kGTFSRouteTypeTrolley:
            
            [_annotationLookup removeAllObjects];
            for (NSDictionary *data in [json objectForKey:@"bus"] )
            {
                
                if ( [_jsonOp isCancelled] )
                    return;
                
                if ( [[data objectForKey:@"Direction"] isEqualToString:@" "] )
                    continue;
                
                TransitViewObject *tvObject = [[TransitViewObject alloc] init];
                
                [tvObject setLat:       [data objectForKey:@"lat"] ];
                [tvObject setLng:       [data objectForKey:@"lng"] ];
                [tvObject setLabel:     [data objectForKey:@"label"] ];
                [tvObject setVehicleID: [data objectForKey:@"VehicleID"] ];
                
                [tvObject setBlockID:       [data objectForKey:@"BlockID"] ];
                [tvObject setDirection:     [data objectForKey:@"Direction"] ];
                [tvObject setDestination:   [data objectForKey:@"destination"] ];
                [tvObject setOffset:        [data objectForKey:@"Offset"] ];
                
                CLLocation *stopLocation = [[CLLocation alloc] initWithLatitude:[[data objectForKey:@"lat"] doubleValue] longitude: [[data objectForKey:@"lng"] doubleValue] ];
                CLLocationDistance dist =  [_locationManager.location distanceFromLocation: stopLocation] / 1609.34f;
                
                [tvObject setDistance: [NSNumber numberWithDouble: dist] ];
                
                [readData addObject: tvObject];
                [self addAnnotationWithObject: tvObject];
            }
            
            break;
            
        case kGTFSRouteTypeRail:
            
            for (NSDictionary *data in json)
            {
                
                if ( [_jsonOp isCancelled] )
                    return;
                
                TrainViewObject *tvObject = [[TrainViewObject alloc] init];
                // These keys need to be exactly as they appear in the returned JSON data
                [tvObject setStartName:[data objectForKey:@"SOURCE"] ];
                [tvObject setEndName  :[data objectForKey:@"dest"] ];
                
                [tvObject setLatitude :[data objectForKey:@"lat"] ];
                [tvObject setLongitude:[data objectForKey:@"lon"] ];
                
                [tvObject setLate     :[data objectForKey:@"late"] ];
                [tvObject setTrainNo  :[data objectForKey:@"trainno"] ];
                
                CLLocation *stopLocation = [[CLLocation alloc] initWithLatitude:[[data objectForKey:@"lat"] doubleValue] longitude: [[data objectForKey:@"lon"] doubleValue] ];
                CLLocationDistance dist = [_locationManager.location distanceFromLocation: stopLocation] / 1609.34f;
                
                [tvObject setDistance: [NSNumber numberWithDouble: dist] ];
                
                NSLog(@"%@",tvObject);
                
                [readData addObject: tvObject];
                [self addAnnotationWithObject: tvObject];
                
            }
            
            break;
            
        default:
            return;
            break;
    }

    
    NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES];
    [readData sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
    
    _tableData = readData;
    if ( _trainDataVC != nil )
    {
        [_trainDataVC updateTableData: _tableData];
    }
    
    [self kickOffAnotherJSONRequest];
    
    
    //    masterList = [readData copy];
    //    readData = nil;
    //
    //    trains = masterList;
    //
    //    [self kickOffAnotherJSONRequest];
    //
    //    [self sortDataWithIndex: _previousIndex];
    
//    [self.tableView reloadData];
    
}


-(void) addAnnotationWithObject: (id) object
{
    
    
    if ( [object isKindOfClass:[TransitViewObject class] ] )  // Bus
    {
        TransitViewObject *tvObject = (TransitViewObject*) object;
        CLLocationCoordinate2D newCoord = CLLocationCoordinate2DMake([tvObject.lat doubleValue], [tvObject.lng doubleValue]);
        
        NSString *direction = tvObject.Direction;
        
        KMLAnnotation *annotation = [[KMLAnnotation alloc] initWithCoordinate:newCoord];

        NSString *annotationTitle;
        if ( [tvObject.Offset intValue] == 1 )
            annotationTitle  = [NSString stringWithFormat: @"Vehicle/Block: %@/%@ (%@ mins ago)", tvObject.VehicleID, tvObject.BlockID, tvObject.Offset];
        else
            annotationTitle  = [NSString stringWithFormat: @"Vehicle/Block: %@/%@ (%@ mins ago)", tvObject.VehicleID, tvObject.BlockID, tvObject.Offset];
        
        [annotation setCurrentSubTitle: [NSString stringWithFormat: @"Destination: %@", tvObject.destination ] ];
        [annotation setCurrentTitle   : annotationTitle];
        [annotation setDirection      : direction];
        
        [annotation setVehicle_id: [NSNumber numberWithInt: [tvObject.VehicleID intValue] ] ];
        
        GTFSRouteType routeType = [self.travelMode intValue];
        if ( ( [direction isEqualToString:@"EastBound"] ) || ( [direction isEqualToString:@"NorthBound"] ) || [direction isEqualToString:@"LOOP"] )
        {
            if ( routeType == kGTFSRouteTypeTrolley )
                [annotation setType:kKMLTrolleyBlue];
            else
                [annotation setType:kKMLBusBlue];
        }
        else if ( ( [direction isEqualToString:@"WestBound"] ) || ( [direction isEqualToString:@"SouthBound"] ) )
        {
            if ( routeType == kGTFSRouteTypeTrolley )
                [annotation setType:kKMLTrolleyRed];
            else
                [annotation setType:kKMLBusRed];
        }
        else
            [annotation setType:kKMLNone];
        
        [_annotationLookup setObject: [NSValue valueWithNonretainedObject: annotation] forKey: tvObject.VehicleID];
        
        [self.mapView addAnnotation: annotation];
    }
    else if ( [object isKindOfClass:[TrainViewObject class] ] )
    {
        TrainViewObject *tvObject = (TrainViewObject*) object;
        
        CLLocationCoordinate2D newCoord = CLLocationCoordinate2DMake([tvObject.latitude doubleValue], [tvObject.longitude doubleValue]);
        
//        mapAnnotation *annotation  = [[mapAnnotation alloc] initWithCoordinate: newCoord];
        KMLAnnotation *annotation = [[KMLAnnotation alloc] initWithCoordinate: newCoord];
        
        if ( [tvObject.trainNo intValue] % 2)
        {
            [annotation setDirection      : @"TrainSouth"];  // Modulus returns 1 on odd
            [annotation setType:kKMLTrainBlue];
        }
        else
        {
            [annotation setDirection      : @"TrainNorth"];  // Modulus returns 0 on even
            [annotation setType:kKMLTrainRed];
        }
        
        // Create the annonation title
        NSString *annotationTitle;
        if ( [tvObject.late intValue] == 0 )
            annotationTitle  = [NSString stringWithFormat: @"Train #%@ (on time)", tvObject.trainNo ];
        else
            annotationTitle  = [NSString stringWithFormat: @"Train #%@ (%d min late)", tvObject.trainNo, [tvObject.late intValue] ];
        
        [annotation setCurrentTitle   : annotationTitle];
        [annotation setCurrentSubTitle: [NSString stringWithFormat: @"%@ to %@", tvObject.startName, tvObject.endName ] ];
        
        [_annotationLookup setObject: [NSValue valueWithNonretainedObject: annotation] forKey: tvObject.trainNo];
        
        [self.mapView addAnnotation: annotation];
        
    }
    
}


// --==  Starts another JSON Request only when the previous one has finished
-(void) kickOffAnotherJSONRequest
{
    
    if ( _killAllTimers )
    {
        [self invalidateTimer];
        return;
    }
    
    //    NSLog(@"NTVVC - kickOffAnotherJSONRequest");
    updateTimer =[NSTimer scheduledTimerWithTimeInterval:JSON_REFRESH_RATE
                                                  target:self
                                                selector:@selector(getLatestJSONData)
                                                userInfo:nil
                                                 repeats:NO];
}


-(void) invalidateTimer
{
    
    if ( updateTimer != nil )
    {
        
        if ( [updateTimer isValid]  )
        {
            [updateTimer invalidate];
            updateTimer = nil;
            NSLog(@"TMVC - Killing updateTimer");
        }
        
    }  // if ( updateTimer != nil )
    
}


#pragma mark - KML Fun (it isn't)
-(void) loadKMLInTheBackground
{
    
    _kmlOp     = [[NSBlockOperation alloc] init];
    
    __weak NSBlockOperation *weakOp = _kmlOp;  // weak reference avoids retain cycle when calling [self processJSONData:...]
    [weakOp addExecutionBlock:^{
        
        if ( ![weakOp isCancelled] )
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self loadkml];
                [SVProgressHUD dismiss];
            }];
        }
        else
        {
            NSLog(@"TVVC - getLatestJSONData: _jsonOp cancelled");
        }
        
    }];
    
    [_mainQueue addOperation: _kmlOp];
    
    //[self getLatestRouteLocations];  // This method uses a asynchronous dispatch queue for now
    
}


#pragma mark - KMLParser
//-(MKOverlayRenderer *) mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
//{
//    
//    NSLog(@"mapView rendererForOverlay");
//    if ([overlay isKindOfClass:[MKPolyline class]])
//    {
//        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
//        
//        renderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
//        renderer.lineWidth   = 3;
//        
//        return renderer;
//    }
//    
//    return nil;
//    
//}


#pragma mark - KMLParser
-(void)loadkml
{
    
    NSString *path;
    
    GTFSRouteType routeType = (GTFSRouteType)[self.travelMode intValue];
    
    if ( routeType == kGTFSRouteTypeRail )
        path = [[NSBundle mainBundle] pathForResource:@"regionalrail" ofType:@"kml"];
    else if ( routeType == kGTFSRouteTypeTrolley || routeType == kGTFSRouteTypeBus )
        path = [[NSBundle mainBundle] pathForResource:self.routeName ofType:@"kml"];  // Hardcoded for now
    else if ( routeType == kGTFSRouteTypeSubway )
        path = [[NSBundle mainBundle] pathForResource:self.routeName ofType:@"kml"];  // Hardcoded for now
    else
        path = nil;
    
    if ( path == nil )
        return;
    
    
    NSURL *url = [NSURL fileURLWithPath:path];
    kmlParser = [[KMLParser alloc] initWithURL:url];
    [kmlParser parseKML];
    
    // Add all of the MKOverlay objects parsed from the KML file to the map.
    NSArray *overlays = [kmlParser overlays];
    //    NSLog(@"TVVC: overlays - %d",[overlays count]);
    [self.mapView addOverlays:overlays];
    
    // Add all of the MKAnnotation objects parsed from the KML file to the map.
    NSArray *annotations = [kmlParser points];
    NSLog(@"TVVC: annotations - %lu",(unsigned long)[annotations count]);
    [self.mapView addAnnotations:annotations];
    
    // Walk the list of overlays and annotations and create a MKMapRect that
    // bounds all of them and store it into flyTo.
    flyTo = MKMapRectNull;
    for (id <MKOverlay> overlay in overlays)
    {
        
        if (MKMapRectIsNull(flyTo))
        {
            flyTo = [overlay boundingMapRect];
        }
        else
        {
            flyTo = MKMapRectUnion(flyTo, [overlay boundingMapRect]);
        }
        
    }
    
    
    for (id <MKAnnotation> annotation in annotations) {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        if (MKMapRectIsNull(flyTo)) {
            flyTo = pointRect;
        } else {
            flyTo = MKMapRectUnion(flyTo, pointRect);
        }
    }
    
    
    // Position the map so that all overlays and annotations are visible on screen.
    self.mapView.visibleMapRect = flyTo;
    
}




-(void) removeAnnotationsFromMapView
{
    NSLog(@"TMVC - removeAnnotationsFromMapView");
    NSMutableArray *annotationsToRemove = [[self.mapView annotations] mutableCopy];  // We want to remove all the annotations minus one
    [annotationsToRemove removeObject: [self.mapView userLocation] ];         // Keep the userLocation annotation on the map
    [self.mapView removeAnnotations: annotationsToRemove];                    // All annotations remaining in the array get removed
}


//-(void) addAnnotationsUsingJSONBusLocations:(NSData*) returnedData
//{
//    
//    //    NSLog(@"TVVC - addAnnotationsUsingJSONBusLocations");
//    [SVProgressHUD dismiss];
//    _stillWaitingOnWebRequest = NO;  // We're no longer waiting on the web request
//    
//    
//    // This method is called once the realtime positioning data has been returned via the API is stored in data
//    NSError *error;
//    NSDictionary *json = [NSJSONSerialization JSONObjectWithData: returnedData options:kNilOptions error:&error];
//    
//    if ( error != nil )
//    return;  // Something bad happened, so just return.
//    
//    [self removeAnnotationsFromMapView];
//    
//    for (NSDictionary *busData in [json objectForKey:@"bus"])
//    {
//        
//        // Loop through all returned bus info...
//        NSNumber *latitude   = [NSNumber numberWithDouble: [[busData objectForKey:@"lat"] doubleValue] ];
//        NSNumber *longtitude = [NSNumber numberWithDouble: [[busData objectForKey:@"lng"] doubleValue] ];
//        
//        CLLocationCoordinate2D newCoord = CLLocationCoordinate2DMake([latitude doubleValue], [longtitude doubleValue]);
//        
//        NSString *direction = [busData objectForKey:@"Direction"];
//        
//        KMLAnnotation *annotation = [[KMLAnnotation alloc] initWithCoordinate: newCoord];
//        
////        mapAnnotation *annotation  = [[mapAnnotation alloc] initWithCoordinate: newCoord];
//        NSString *annotationTitle  = [NSString stringWithFormat: @"BlockID: %@ (%@ min)", [busData objectForKey:@"BlockID"], [busData objectForKey:@"Offset"]];
//        
//        [annotation setCurrentSubTitle: [NSString stringWithFormat: @"Destination: %@", [busData objectForKey:@"destination"]] ];
//        [annotation setCurrentTitle   : annotationTitle];
//        [annotation setDirection      : direction];
//
//        GTFSRouteType routeType = [self.travelMode intValue];
//        if ( ( [direction isEqualToString:@"EastBound"] ) || ( [direction isEqualToString:@"SouthBound"] ) )
//        {
//            if ( routeType == kGTFSRouteTypeTrolley )
//                [annotation setType:kKMLTrolleyBlue];
//            else
//                [annotation setType:kKMLBusBlue];
//        }
//        else if ( ( [direction isEqualToString:@"WestBound"] ) || ( [direction isEqualToString:@"NorthBound"] ) )
//        {
//            if ( routeType == kGTFSRouteTypeTrolley )
//                [annotation setType:kKMLTrolleyRed];
//            else
//                [annotation setType:kKMLBusRed];
//        }
//        else if ( [direction isEqualToString: @"TrainSouth"] )
//        {
//            [annotation setType:kKMLTrainBlue];
//        }
//        else if ( [direction isEqualToString: @"TrainNorth"] )
//        {
//            [annotation setType:kKMLTrainRed];
//        }
//        
//        [self.mapView addAnnotation: annotation];
//        
//    }
//    
//    [self kickOffAnotherMapKitJSONRequest];
//    //    NSLog(@"TVVC - addAnnotationsUsingJSONBusLocations -- added %d annotations", [[json objectForKey:@"bus"] count]);
//    
//    //    [SVProgressHUD dismiss];  // We got data, even if it's nothing.  Dismiss the Loading screen...
//    
//}


-(void) kickOffAnotherMapKitJSONRequest
{
    
    if ( _killAllTimers )
    {
        [self invalidateTimer];
        return;
    }
    
    //    NSLog(@"TVVC -(void) kickOffAnotherMapKitJSONRequest");
//    updateTimer =[NSTimer scheduledTimerWithTimeInterval:JSON_REFRESH_RATE
//                                                  target:self
//                                                selector:@selector(getLatestRouteLocations)
//                                                userInfo:nil
//                                                 repeats:NO];
    
}




#pragma mark - MKMapViewDelegate Methods
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    
//    mapAnnotation *pin = (mapAnnotation*)view.annotation;
// 
//    annotationTimer =[NSTimer scheduledTimerWithTimeInterval:1.25f
//                                                      target:self
//                                                    selector:@selector(updateAnnotation:)
//                                                    userInfo:pin
//                                                     repeats:NO];

    
}



// gga commented
-(MKOverlayView*) mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
//    NSLog(@"TMVC -mapView viewForOverlay");
    return [kmlParser viewForOverlay: overlay];
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    
    NSLog(@"TMVC - @mapView:%@, viewForAnnotation:%@", mapView, annotation);
    if ( [annotation isKindOfClass:[KMLAnnotation class]] )
    {
        // TODO: Verify that KMLAnnotationView doesn't crash and burn when a non-KMLAnnotation class it passed to it.
        KMLAnnotationView *annotationView = [[KMLAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Vehicle"];
        [annotationView setCanShowCallout:YES];
        return annotationView;
    }
    else
    {
        return nil;
    }
    
}

-(void) updateAnnotation:(NSTimer*) timerObj
{
    
//    MKPinAnnotationView *anoView = (MKPinAnnotationView*)[timerObj userInfo];
    
    // gga commented out on 9/22/15; no idea what this is
//    NSLog(@"TMVC: updateAnnotation");
//    mapAnnotation *ano = (mapAnnotation*)[timerObj userInfo];
//    
//    [ano setCurrentTitle:@"Greg"];
//    NSLog(@"%@", ano);
    
}


- (void)mapView:(MKMapView *)thisMapView regionDidChangeAnimated:(BOOL)animated
{
    
    NSLog(@"TMVC - mapView regionDidChangeAnimated");
    MKCoordinateRegion mapRegion;
    // set the center of the map region to the now updated map view center
    mapRegion.center = thisMapView.centerCoordinate;
    
    mapRegion.span.latitudeDelta = 0.3; // you likely don't need these... just kinda hacked this out
    mapRegion.span.longitudeDelta = 0.3;
    
}



@end
