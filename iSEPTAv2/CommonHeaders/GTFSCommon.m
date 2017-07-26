//
//  GTFSCommon.m
//  iSEPTA
//
//  Created by septa on 1/2/2014
//  Copyright (c) 2013 SEPTA. All rights reserved.
//

#import "GTFSCommon.h"

@interface GTFSCommon ()

@end

@implementation GTFSCommon
{
    
}


+(NSString*) filePath
{
#if FUNCTION_NAMES_ON
    NSLog(@"GTFSCommon: filePath");
#endif
    
    
    // Build the path where SEPTA.sqlite should exist
    NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *dbPath = [NSString stringWithFormat:@"%@/SEPTA.sqlite", [paths objectAtIndex:0] ];

    // Check if SEPTA.sqlite exists
    bool b = [[NSFileManager defaultManager] fileExistsAtPath:dbPath];    
    
    if ( !b )  // If the file does not exist
    {
        [GTFSCommon uncompressWithPath:dbPath];
    }
    
    return dbPath;
    
}


+(void) uncompressWithPath: (NSString*) dbPath
{
    
    NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"SEPTA" ofType:@"zip"];
    NSString *md5Path = [[NSBundle mainBundle] pathForResource:@"SEPTA" ofType:@"md5"];
    
    // Uncompress the zip file to get SEPTA.sqlite
    if ( zipPath != nil )
    {
        
        NSArray   *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString  *uncompressPath = [paths objectAtIndex:0];
        
        ZipArchive *zip = [[ZipArchive alloc] init];
        if ( [zip UnzipOpenFile: zipPath] )
        {
            
            //                NSArray *contents = [zip getZipFileContents];
            //                NSLog(@"Contents: %@", contents);
            
            //        BOOL ret = [zip UnzipFileTo:[[self filePath] stringByDeletingLastPathComponent] overWrite:YES];
            BOOL ret = [zip UnzipFileTo:uncompressPath overWrite:YES];
            if ( NO == ret )
            {
//                    NSLog(@"Unable to unzip");
            }
            
            
            NSDirectoryEnumerator* dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: zipPath];
            NSString* file;
            NSError* error = nil;
            NSUInteger count = 1;
            while ((file = [dirEnum nextObject]))
            {
                count += 1;
                NSString* fullPath = [zipPath stringByAppendingPathComponent:file];
                NSDictionary* attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:&error];
                NSLog(@"file is not zero length: %@", attrs);
            }
            
            //                NSLog(@"%ld == %ld, files extracted successfully", (unsigned long)count, (unsigned long)[contents count]);
            
            NSURL *dbPathURL = [NSURL fileURLWithPath:dbPath];
            
            NSError *pathError = nil;
            BOOL success = [dbPathURL setResourceValue:[NSNumber numberWithBool: YES] forKey:NSURLIsExcludedFromBackupKey error:&pathError];
            if ( !success )
            {
                //                    NSLog(@"Error excluding %@ from backup %@", [dbPathURL lastPathComponent], error);
            }
            else
            {
                //                    NSLog(@"Excluded %@ from backup", [dbPathURL lastPathComponent]);
            }
            
            
            // Copy the MD5 over to the Cache Directory as well
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            // Find the location of the MD5 file
            NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *srcPath = [NSString stringWithFormat:@"%@/SEPTA.md5", [paths objectAtIndex:0] ];
            NSError *md5Error;

            if ( md5Path == nil )  // Check that srcPath exists
            {
                // NSLog(@"Could not find: %@", srcPath);
            }
            else
            {
                if ( [fileManager fileExistsAtPath: srcPath] )  // Check if the md5 file already exists
                {
                    [fileManager removeItemAtPath:srcPath error:&md5Error];  // Since it does, remove it
                }
                
                [fileManager copyItemAtPath:md5Path toPath:srcPath error:&md5Error];  // Copy the md5 file over
            }
            
        }  // if ( [zip UnzipOpenFile: zipPath] )
        
        [zip UnzipCloseFile];
        
    }  // if ( zipPath != nil )
    
}


+(BOOL) checkService:(int) serviceID withArray:(NSArray *)serviceIDArray
{
    
    for (NSNumber *sid in serviceIDArray)
    {
        if ( [sid intValue] == serviceID )
            return YES;
    }
    
    return NO;
}


+(BOOL) checkService:(int) serviceID withService:(int) otherID
{
    
    if ( otherID == serviceID )
        return YES;
    else
        return NO;
    
}




+(NSString*) getServiceIDStrFor:(GTFSRouteType) route  withOffset:(GTFSCalendarOffset) offset
{
    
    NSArray *sArr = [GTFSCommon getServiceIDFor:route withOffset:offset];
    
    NSMutableString *string = [[NSMutableString alloc] init];
    int count = 0;
    for (NSNumber *sid in sArr)
    {
        if ( count++ > 0 )
            [string appendString:@", "];
        
        [string appendString:[NSString stringWithFormat:@"%d",[sid intValue] ] ];
    }
    
    return string;

}


+(NSArray*) getServiceIDFor:(GTFSRouteType) route  withOffset:(GTFSCalendarOffset) offset
{
    
#if FUNCTION_NAMES_ON
    NSLog(@"GTFSCommon: getServiceIDFor: %ld", (long)route);
#endif
    
    NSInteger service_id = 0;
    
    //    NSLog(@"filePath: %@", [self filePath]);
    FMDatabase *database = [FMDatabase databaseWithPath: [GTFSCommon filePath] ];
    
    if ( ![database open] )
    {
        [database close];
        return 0;
    }
    
    // What is the current day of the week.
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *comps = [gregorian components:NSCalendarUnitWeekday fromDate:[NSDate date] ];
    NSInteger weekday = [comps weekday];  // Sunday is 1, Mon (2), Tue (3), Wed (4), Thur (5), Fri (6) and Sat (7)

    int dayOfWeek = 0;  // Sun: 64, Mon: 32, Tue: 16, Wed: 8, Thu: 4, Fri: 2, Sat: 1
    
    // We're assuming here that a holiday can only have ONE valid service_id and none of this "I'm Friday, I'm a 1 and 4" nonsense
    if ( ( service_id = [GTFSCommon isHoliday:route withOffset:offset] ) )
    {
        NSMutableArray *serviceArr = [[NSMutableArray alloc] init];
        [serviceArr addObject: [NSNumber numberWithLong:service_id] ];
        return serviceArr;  // Since it is a holiday, skip everything else and just return this
    }
    
    switch (offset) {
            
        case kGTFSCalendarOffsetToday:
            dayOfWeek = pow(2,(7-weekday) );
            break;
            
        case kGTFSCalendarOffsetSat:
            dayOfWeek = pow(2,0); // 000 0001 (SuMoTu WeThFrSa), Saturday
            break;
            
        case kGTFSCalendarOffsetSun:
            dayOfWeek = pow(2,6); // 100 0000 (SuMoTu WeThFrSa), Sunday
            break;
            
        case kGTFSCalendarOffsetWeekday:
            dayOfWeek = pow(2,5); // 010 0000 (SuMoTu WeThFrSa), Monday
            break;
            
        case kGTFSCalendarOffsetTomorrow:

            dayOfWeek = pow(2,(7-weekday) );  // Get the current day
            
            if ( dayOfWeek & 1 )  // If day of the week is Sat (1), move it to Sunday
                dayOfWeek = 64;
            else
                dayOfWeek = dayOfWeek >> 1;  // If not Sat, shift right by 1 (or divide by 2^1)
            
            break;
            
        case kGTFSCalendarOffsetYesterday:
            
            dayOfWeek = pow(2,(7-weekday) );
            if ( dayOfWeek & 64 )
                dayOfWeek = 1;
            else
                dayOfWeek = dayOfWeek << 1;
            
            break;
            
        default:
            break;
    }
    
    //    int dayOfWeek = pow(2,(7-weekday) );
    
    NSString *queryStr = [NSString stringWithFormat:@"SELECT service_id, days FROM calendarDB WHERE (days & %d)", dayOfWeek];
    
    if ( route == kGTFSRouteTypeRail )
        queryStr = [queryStr stringByReplacingOccurrencesOfString:@"DB" withString:@"_rail"];
    else
        queryStr = [queryStr stringByReplacingOccurrencesOfString:@"DB" withString:@"_bus"];
    
    FMResultSet *results = [database executeQuery: queryStr];
    if ( [database hadError] )  // Check for errors
    {
        
//        int errorCode = [database lastErrorCode];
//        NSString *errorMsg = [database lastErrorMessage];
        
//        NSLog(@"IVC - query failure, code: %d, %@", errorCode, errorMsg);
//        NSLog(@"IVC - query str: %@", queryStr);
        
        return 0;  // If an error occurred, there's nothing else to do but exit
        
    } // if ( [database hadError] )

    
    NSMutableArray *serviceArr = [[NSMutableArray alloc] init];
    
    while ( [results next] )
    {
        service_id = [results intForColumn:@"service_id"];
        [serviceArr addObject: [NSNumber numberWithLong:service_id] ];
    }
    
//    return (NSInteger)service_id;
    
    [database close];

    return serviceArr;
    
}


+(NSString *) nextHoliday
{
    // Returns the date of the next holiday, or how many days until, or the number of ponies I'm thinking about?  Hint: 0!
    return nil;
}



+(NSInteger) isHoliday:(GTFSRouteType) routeType withOffset:(GTFSCalendarOffset) offset
{
    
#if FUNCTION_NAMES_ON
    NSLog(@"GTFSCommon: isHoliday");
#endif
    
 
//    NSDate *today = [[NSDate alloc] init];
//    NSCalendar *gregorian = [[NSCalendar alloc]
//                             initWithCalendarIdentifier:NSGregorianCalendar];
//    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
//    [offsetComponents setDay:1];
//    [offsetComponents setHour:1];
//    [offsetComponents setMinute:30];
//    // Calculate when, according to Tom Lehrer, World War III will end
//    NSDate *endOfWorldWar3 = [gregorian dateByAddingComponents:offsetComponents
//                                                        toDate:today options:0];

    
    // The curse of the holiday
    //   Need to determine the current day of the week
    //   Need to determine what the offset is: Now, Weekday, Sat, Sun
    
    // If Now Tab, nothing changes
    // If today is a Mon-Fri and Weekday Tab, check if today is a holiday
    // If today is a Mon-Fri and Sat Tab, get the date for Sat and check if that's a holiday
    // If today is a Mon-Fri and Sun Tab, get the date for Sun and check if that's a holiday
    
    // If today is a Sat and Weekday Tab, get date for Mon and check if that's a holiday
    // If today is a Sat and Sat Tab, check if today is a holiday
    // If today is a Sat and Sun Tab, add a day to the add and check if that's a holiday
    
    // If today is a Sun and Weekday Tab, get tomorrow's date and check if that's a holiday
    // If today is a Sun and Sat Tab, get the date for the next Sat and check if that's a holiday
    // If today is a Sun and Sun Tab, check if today is a holiday

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYYMMdd"];  // Format is YYYYMMDD, e.g. 20131029
    
    NSString *nowStr;
    NSDate *now = [NSDate date];
    if ( offset == kGTFSCalendarOffsetToday )
    {
        nowStr = [dateFormatter stringFromDate: now];
    }
    else if ( offset == kGTFSCalendarOffsetWeekday )
    {
        return 0;  // Right now, this is problematic because Weekday covers Mon-Fri, but a holiday would only be one of those days
        // Do you return a value if 1 day out of 5 is a holiday.  2 out of 5?
    }
    else
    {
        
        // What is the current day of the week.
        NSCalendar *gregorian = [NSCalendar currentCalendar];
        NSDateComponents *comps = [gregorian components:NSCalendarUnitWeekday fromDate:[NSDate date] ];
        NSInteger today = [comps weekday];  // Sunday is 1, Mon (2), Tue (3), Wed (4), Thur (5), Fri (6) and Sat (7)

        NSInteger daysToAdd = 0;
        
        if ( offset == kGTFSCalendarOffsetSat )
        {
            if ( today != 7 )  // If today is not Saturday (7)
            {
                daysToAdd = (7-today);
            }
        }
        else if ( offset == kGTFSCalendarOffsetSun )
        {
            if ( today != 1 ) // If today is not Sunday (1)
            {
                daysToAdd = (8-today);
            }
        }
        
        NSDate *newDate = [now dateByAddingTimeInterval:60*60*24*daysToAdd];
        nowStr = [dateFormatter stringFromDate: newDate];
        
    }
    
    
    // For testing...
//    now = @"20141225";
    
    // Now needs to factor in the offset.
    
//    NSLog(@"filePath: %@", [GTFSCommon filePath]);
    FMDatabase *database = [FMDatabase databaseWithPath: [self filePath] ];
    
    if ( ![database open] )
    {
        [database close];
        return 0;
    }
    
    NSString *queryStr = [NSString stringWithFormat:@"SELECT service_id, date FROM holidayDB WHERE date=%@", nowStr];
    
    if ( routeType == kGTFSRouteTypeRail )
        queryStr = [queryStr stringByReplacingOccurrencesOfString:@"DB" withString:@"_rail"];
    else
        queryStr = [queryStr stringByReplacingOccurrencesOfString:@"DB" withString:@"_bus"];
            
    FMResultSet *results = [database executeQuery: queryStr];
    if ( [database hadError] )  // Check for errors
    {
            
//        int errorCode = [database lastErrorCode];
//        NSString *errorMsg = [database lastErrorMessage];
        
//        NSLog(@"IVC - query failure, code: %d, %@", errorCode, errorMsg);
//        NSLog(@"IVC - query str: %@", queryStr);
        
        return 0;  // If an error occurred, there's nothing else to do but exit
            
    } // if ( [database hadError] )
    
    
    NSInteger service_id = 0;
    NSMutableArray *serviceArr = [[NSMutableArray alloc] init];
    while ( [results next] )
    {
        service_id = [results intForColumn:@"service_id"];
        [serviceArr addObject: [NSNumber numberWithLong:service_id] ];
    }
    
    [database close];
    
    // TODO: Return array instead of integer
    // Use case: add additional service on a specific day, e.g. Christmas Eve.
    // service_id, date
    // 1, xx/yy/zz  -- Normal weekday service
    // 8, xx/yy/zz  -- Additional service on that day
    
    return service_id;
    
    
    
}


+(BOOL) isServiceGood:(int) serviceID forRouteType:(GTFSRouteType) routeType withOffset:(GTFSCalendarOffset) offset
{
    
    return [GTFSCommon checkService:serviceID withArray: [GTFSCommon getServiceIDFor:routeType withOffset:offset] ];
    
}


+(BOOL) date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    
    if ( beginDate == nil || endDate == nil )
        return NO;  // If either date fields are nil, return NO
    
    if ([date compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([date compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}


@end
