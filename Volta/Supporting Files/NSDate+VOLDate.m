//
//  NSDate+VOLDate.m
//  Volta
//
//  Created by Jonathan Cabrera on 12/22/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//

#import "NSDate+VOLDate.h"

@implementation NSDate (VOLDate)

- (BOOL)isBetweenDate:(NSDate *)beginDate
              andDate:(NSDate *)endDate
{
    return (([self compare:beginDate] != NSOrderedAscending) && ([self compare:endDate] != NSOrderedDescending));
}

- (BOOL)isAfterDate:(NSDate *)date
{
    if (([self compare:date]) == NSOrderedDescending) {
        return YES;
    }
    
    return NO;
}


@end
