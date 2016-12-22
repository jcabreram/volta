//
//  NSDate+VOLDate.m
//  Volta
//
//  Created by Jonathan Cabrera on 12/22/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "NSDate+VOLDate.h"

@implementation NSDate (VOLDate)

- (BOOL)isBetweenDate:(NSDate *)beginDate
              andDate:(NSDate *)endDate
{
    if ([self compare:beginDate] == NSOrderedAscending) {
        return NO;
    }
    
    if ([self compare:endDate] == NSOrderedDescending) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isAfterDate:(NSDate *)date
{
    if (([self compare:date]) == NSOrderedDescending) {
        return YES;
    }
    
    return NO;
}


@end
