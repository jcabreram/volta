//
//  TimesheetWeek.m
//  Volta
//
//  Created by Jonathan Cabrera on 12/19/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "TimesheetWeek.h"

@implementation TimesheetWeek

- (instancetype)init
{
    return [self initWithWeekNumber:1
                               year:2017
                             status:Status_NotSubmitted];
}

- (instancetype)initWithWeekNumber:(NSInteger)weekNumber
                              year:(NSInteger)year
                            status:(Status)status
{
    return [self initWithWeekNumber:weekNumber
                               year:year
                             status:status
                        hoursPerDay:[@[[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null]] mutableCopy]
              withProjectsForMonday:[[NSMutableDictionary alloc] init]
                            tuesday:[[NSMutableDictionary alloc] init]
                          wednesday:[[NSMutableDictionary alloc] init]
                           thursday:[[NSMutableDictionary alloc] init]
                             friday:[[NSMutableDictionary alloc] init]
                           saturday:[[NSMutableDictionary alloc] init]
                             sunday:[[NSMutableDictionary alloc] init]];
}


- (instancetype)initWithWeekNumber:(NSInteger)weekNumber
                              year:(NSInteger)year
                            status:(Status)status
                       hoursPerDay:(NSMutableArray *)hoursPerDay
             withProjectsForMonday:(NSMutableDictionary<NSString *, NSNumber *> *)monday
                           tuesday:(NSMutableDictionary<NSString *, NSNumber *> *)tuesday
                         wednesday:(NSMutableDictionary<NSString *, NSNumber *> *)wednesday
                          thursday:(NSMutableDictionary<NSString *, NSNumber *> *)thursday
                            friday:(NSMutableDictionary<NSString *, NSNumber *> *)friday
                          saturday:(NSMutableDictionary<NSString *, NSNumber *> *)saturday
                            sunday:(NSMutableDictionary<NSString *, NSNumber *> *)sunday
{
    self = [super init];
    
    if (self) {
        _weekNumber = weekNumber;
        _year = year;
        _status = status;
        _hoursPerDay = hoursPerDay;
        _mon = monday;
        _tue = tuesday;
        _wed = wednesday;
        _thu = thursday;
        _fri = friday;
        _sat = saturday;
        _sun = sunday;
    }
    
    return self;
}

- (void)addWorkForWeekDay:(WeekDay)day
           withProjectKey:(NSString *)projectKey
            numberOfHours:(NSNumber *)numberOfHours
{
    NSMutableDictionary *projectWork = [self projectsForDay:day];
    
    projectWork[projectKey] = numberOfHours;
    
    self.hoursPerDay[day] = @([self.hoursPerDay[day] doubleValue] + [numberOfHours doubleValue]);
}

- (NSNumber *)allocatedHours
{
    double allocatedHours = 0.0;
    for (NSNumber *dayHours in self.hoursPerDay) {
        if ([dayHours isKindOfClass:[NSNumber class]]) {
            allocatedHours += [dayHours doubleValue];
        }
    }
    
    return @(allocatedHours);
}

- (NSDate *)startingDate
{
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *comp = [[NSDateComponents alloc] init];
    comp.weekday = 2; // Monday
    comp.weekOfYear = self.weekNumber;
    comp.yearForWeekOfYear = self.year;
    
    return [cal dateFromComponents:comp];
}

- (NSMutableDictionary *)projectsForDay:(WeekDay)day
{
    NSDictionary *projectWork;
    
    switch (day) {
        case WeekDay_Monday:
            projectWork = self.mon;
            break;
            
        case WeekDay_Tuesday:
            projectWork = self.tue;
            break;
            
        case WeekDay_Wednesday:
            projectWork = self.wed;
            break;
            
        case WeekDay_Thursday:
            projectWork = self.thu;
            break;
            
        case WeekDay_Friday:
            projectWork = self.fri;
            break;
            
        case WeekDay_Saturday:
            projectWork = self.sat;
            break;
            
        case WeekDay_Sunday:
            projectWork = self.sun;
            break;
            
        default:
            break;
    }
    
    return [projectWork mutableCopy];
}

@end
