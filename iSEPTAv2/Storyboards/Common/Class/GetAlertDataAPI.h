//
//  GetAlertDataAPI.h
//  iSEPTA
//
//  Created by septa on 9/16/13.
//  Copyright (c) 2013 SEPTA. All rights reserved.
//

#import <Foundation/Foundation.h>


// --==  PODs  ==--
#import <AFNetworking/AFNetworking.h>


// --==  Model  ==--
#import "SystemAlertObject.h"


#import "SEPTACommon.h"
#import "NSDictionary+ObjectKeyNil.h"


@protocol GetAlertDataAPIProtocol <NSObject>

@optional
-(void) alertFetched:(NSMutableArray*) alert;

@end

@interface GetAlertDataObject : NSObject

@property (nonatomic, strong) NSString *alertName;
@property (nonatomic, strong) NSNumber *alertType;

@end


@interface GetAlertDataAPI : NSObject

//@property (nonatomic, strong) NSString *route_short_name;
@property (nonatomic, weak) id <GetAlertDataAPIProtocol>delegate;

-(NSArray*) getOperations;
-(void) fetchAlert;
-(void) addRoute:(NSString*) routeName;
-(void) addRoute:(NSString*) routeName ofModeType:(SEPTARouteTypes) type;
-(void) removeRoute:(NSString*) routeName;

-(void) clearAllRoutes;

-(NSDictionary*) getAlert;

+(NSString *)convertHTML:(NSString *)html;

@end
