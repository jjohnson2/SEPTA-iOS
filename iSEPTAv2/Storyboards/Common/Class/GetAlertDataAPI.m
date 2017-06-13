//
//  GetAlertDataAPI.m
//  iSEPTA
//
//  Created by septa on 9/16/13.
//  Copyright (c) 2013 SEPTA. All rights reserved.
//

#import "GetAlertDataAPI.h"

@implementation GetAlertDataObject



@end



@implementation GetAlertDataAPI
{
    AFHTTPRequestOperation *_jsonOperation;
    NSMutableArray *_operationArr;
    
//    SystemAlertObject *_alert;
    NSMutableDictionary *_alerts;
    NSMutableArray *_routeNamesArr;
}


-(id) init
{
    
    self = [super init];
    if ( self )
    {
        _alerts = [[NSMutableDictionary alloc] init];
        _routeNamesArr = [[NSMutableArray alloc] init];
    }
    return self;
    
}

-(void) clearAllRoutes
{
    [_routeNamesArr removeAllObjects];
}


-(void) addRoute:(NSString*) routeName ofModeType:(SEPTARouteTypes) type
{
    
    if ( routeName == nil )
        return;
    
    NSString *alertName;
    
    switch (type)
    {
            
        case kSEPTATypeBus:
        
            if ( [routeName isEqualToString:@"BSO"] || [routeName isEqualToString:@"MFO"] )
                alertName = [NSString stringWithFormat:@"rr_route_%@", [routeName lowercaseString] ];
            else
                alertName = [NSString stringWithFormat:@"bus_route_%@", routeName];
        
            break;
        case kSEPTATypeRail:
        {
            NSMutableDictionary *shortToAlertNameLookUp = [[NSMutableDictionary alloc] init];
            
            //    [shortToAlertNameLookUp setObject:@"AlertName" forKey:@"ShortName"];
            [shortToAlertNameLookUp setObject:@"che" forKey:@"CHE"];
            [shortToAlertNameLookUp setObject:@"chw" forKey:@"CHW"];
            [shortToAlertNameLookUp setObject:@"cyn" forKey:@"CYN"];
            
            [shortToAlertNameLookUp setObject:@"fxc" forKey:@"FOX"];
            [shortToAlertNameLookUp setObject:@"landdoy" forKey:@"LAN"];
            [shortToAlertNameLookUp setObject:@"landdoy" forKey:@"DOY"];
            [shortToAlertNameLookUp setObject:@"med" forKey:@"MED"];
            
            [shortToAlertNameLookUp setObject:@"nor" forKey:@"NOR"];
            [shortToAlertNameLookUp setObject:@"pao" forKey:@"PAO"];
            [shortToAlertNameLookUp setObject:@"trent" forKey:@"TRE"];
            
            [shortToAlertNameLookUp setObject:@"warm" forKey:@"WAR"];
            [shortToAlertNameLookUp setObject:@"wilm" forKey:@"WIL"];
            [shortToAlertNameLookUp setObject:@"wtren" forKey:@"WTR"];
            
            [shortToAlertNameLookUp setObject:@"apt" forKey:@"AIR"];
            
            [shortToAlertNameLookUp setObject:@"gc" forKey:@"GC"];
            
            alertName = [NSString stringWithFormat:@"rr_route_%@", [shortToAlertNameLookUp objectForKey: routeName] ];

        }
            break;
        case kSEPTATypeTrolley:
            alertName = [NSString stringWithFormat:@"trolley_route_%@", routeName];
            break;
        case kSEPTATypeTracklessTrolley:
            alertName = [NSString stringWithFormat:@"trolley_route_%@", routeName];
            break;
        case kSEPTATypeBSL:
            
            break;
        case kSEPTATypeMFL:
            
            break;
        case kSEPTATypeNHSL:
            
            break;
        default:
            alertName = routeName;
            break;
            
    } // switch (type)

    if ( alertName == nil ) // If alertName is null, then don't add it to the _routeNamesArr object.
        return;
    
    if ( ![_routeNamesArr containsObject: alertName] )
    {
        if ( alertName != nil )
            [_routeNamesArr addObject: alertName];
    }
    
}


-(void) addRoute:(NSString*) routeName
{
    
    if ( routeName == nil )
        return;
    
    if ( ![_routeNamesArr containsObject: routeName] )
        [_routeNamesArr addObject: routeName];
    
}


-(void) removeRoute:(NSString*) routeName
{
    
    if ( routeName == nil )
        return;
    
//    if ( [_routeNamesArr containsObject: routeName] )
    [_routeNamesArr removeObject: routeName];
    
}

-(NSArray*) getOperations
{
    
    if ( _routeNamesArr == nil )
        return nil;  // Need a route to fetch first
    
    // Lettered bus routes will fall into rr_route_ category.  =\
    
    
    // --==================--
    // --==  Get Alerts  ==--
    // --==================--
    
    for (NSString *routeName in _routeNamesArr)
    {
        
        NSString *alertRouteName;
        
        
        // This is a crappy way of handling this, but if the routeName contains a '_' it was properly formatted using addRoute:ofModeType:
        //   instead of addRoute: which the condition statement inside is built to handle
        if ( [routeName rangeOfString:@"_"].location == NSNotFound && ![routeName isEqualToString:@"generic"] )
        {
            
            if ( [routeName intValue] > 0 )
            {
                alertRouteName = [NSString stringWithFormat:@"bus_route_%@", routeName];
            }
            else
            {
                
                if ( [routeName isEqualToString:@"MFL"] || [routeName isEqualToString:@"MFO"] || [routeName isEqualToString:@"BSO"] || [routeName isEqualToString:@"BSL"] )
                    alertRouteName = [NSString stringWithFormat:@"rr_route_%@", [routeName lowercaseString] ];
                else
                    alertRouteName = [NSString stringWithFormat:@"rr_route_%@", routeName];
                
            }
            
        }
        else
            alertRouteName = routeName;  // Since '_' was found, routeName is already good
        
        
        
        NSString *url = [NSString stringWithFormat:@"https://www3.septa.org/hackathon/Alerts/get_alert_data.php?req1=%@", alertRouteName];
//        NSLog(@"GetAlertDataAPI - url: %@", url);
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] ];
        
        _jsonOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [_jsonOperation setResponseSerializer: [AFJSONResponseSerializer serializer] ];
        
        __weak id weakSelf = self;
        [_jsonOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSDictionary *jsonDict = (NSDictionary *) responseObject;
             [weakSelf loadIndividualAlertData: jsonDict forRoute: routeName];
             
         }failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             NSLog(@"GADA - fetchAlert, Request Failure Because %@",[error userInfo]);
         }
         ];
        
        [_jsonOperation start];
        [_operationArr addObject:_jsonOperation];
        
    }  // for (NSString *routeName in _routeNamesArr)

    return [NSArray arrayWithArray: _operationArr];
    
}


-(void) fetchAlert
{
    
    
    
    if ( _routeNamesArr == nil )
        return;  // Need a route to fetch first
    
    // Lettered bus routes will fall into rr_route_ category.  =\
    
    
    // --==================--
    // --==  Get Alerts  ==--
    // --==================--
    
    for (NSString *routeName in _routeNamesArr)
    {
        
        NSString *alertRouteName;
        
        
        // This is a crappy way of handling this, but if the routeName contains a '_' it was properly formatted using addRoute:ofModeType:
        //   instead of addRoute: which the condition statement inside is built to handle
        if ( [routeName rangeOfString:@"_"].location == NSNotFound && ![routeName isEqualToString:@"generic"] )
        {
            
            if ( [routeName intValue] > 0 )
            {
                alertRouteName = [NSString stringWithFormat:@"bus_route_%@", routeName];
            }
            else
            {
                
                if ( [routeName isEqualToString:@"MFL"] || [routeName isEqualToString:@"MFO"] || [routeName isEqualToString:@"BSO"] || [routeName isEqualToString:@"BSL"] )
                    alertRouteName = [NSString stringWithFormat:@"rr_route_%@", [routeName lowercaseString] ];
                else
                    alertRouteName = [NSString stringWithFormat:@"rr_route_%@", routeName];
                
            }
            
        }
        else
            alertRouteName = routeName;  // Since '_' was found, routeName is already good
        
        
        
        NSString *url = [NSString stringWithFormat:@"https://www3.septa.org/hackathon/Alerts/get_alert_data.php?req1=%@", alertRouteName];
//        NSLog(@"GetAlertDataAPI - url: %@", url);
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] ];
        
        _jsonOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [_jsonOperation setResponseSerializer: [AFJSONResponseSerializer serializer] ];
        
        __weak typeof(self) weakSelf = self;
        [_jsonOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
        {
            NSDictionary *jsonDict = (NSDictionary *) responseObject;
            [weakSelf loadIndividualAlertData: jsonDict forRoute: routeName];
            
        }failure:^(AFHTTPRequestOperation *operation, NSError *error)
        {
            NSLog(@"GADA - fetchAlert, Request Failure Because %@",[error userInfo]);
        }
        ];
        
        [_jsonOperation start];
        [_operationArr addObject:_jsonOperation];
        
    }  // for (NSString *routeName in _routeNamesArr)
    
    
}


-(void) cancelAllOperations
{
    
    for (AFHTTPRequestOperation *jOps in _operationArr)
    {
        [jOps cancel];
    }
    
}

+(NSString *)convertHTML:(NSString *)html {
    
    NSScanner *myScanner;
    NSString *text = nil;
    myScanner = [NSScanner scannerWithString:html];
    
    while ([myScanner isAtEnd] == NO)
    {
        [myScanner scanUpToString:@"<" intoString:NULL] ;
        [myScanner scanUpToString:@">" intoString:&text] ;
        
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
    }
    
    html = [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return html;
}


-(void) loadIndividualAlertData: (NSDictionary*) jsonDict forRoute: (NSString*) routeName
{
    
    
    NSMutableArray *alertsArr = [[NSMutableArray alloc] init];
    
    if ( jsonDict != nil )
    {
        
        
        [_alerts removeAllObjects];
        for (NSDictionary *data in jsonDict)
        {
            SystemAlertObject *saObject = [[SystemAlertObject alloc] init];
            
            [saObject setRoute_id:   [data objectForKeyOrNil:@"route_id"] ];
            [saObject setRoute_name: [data objectForKeyOrNil:@"route_name"] ];
            
            [saObject setCurrent_message:  [GetAlertDataAPI convertHTML: [data objectForKeyOrNil:@"current_message"] ] ];
            [saObject setAdvisory_message: [data objectForKeyOrNil:@"advisory_message"] ];
            
            [saObject setDetour_message:        [data objectForKeyOrNil:@"detour_message"] ];
            [saObject setDetour_start_location: [data objectForKeyOrNil:@"detour_start_location"] ];
            
            [saObject setDetour_start_date_time: [data objectForKeyOrNil:@"detour_start_date_time"] ];
            [saObject setDetour_end_date_time:   [data objectForKeyOrNil:@"detour_end_date_time"] ];
            
            [saObject setDetour_reason: [data objectForKeyOrNil:@"detour_reason"] ];
            [saObject setLast_updated:  [data objectForKeyOrNil:@"last_updated"] ];
            
            
            [alertsArr addObject:saObject];

        }
        
        // TODO: Always call alertFeteched, even if empty
        // PLEASEEXPLAIN: Why?!
        if ( [self.delegate respondsToSelector:@selector(alertFetched:)] )
        {
            [self.delegate alertFetched:alertsArr];
        }

        
    }  // if (jsonDict != nil )
    
}


-(NSDictionary*) getAlert
{
    return _alerts;
}


@end
