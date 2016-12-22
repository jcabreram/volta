//
//  NSDate+VOLDate.h
//  Volta
//
//  Created by Jonathan Cabrera on 12/22/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (VOLDate)

- (BOOL)isBetweenDate:(NSDate *)beginDate
              andDate:(NSDate *)endDate;

- (BOOL)isAfterDate:(NSDate *)date;

@end
