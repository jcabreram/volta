//
//  TimesheetWeek.h
//  Volta
//
//  Created by Jonathan Cabrera on 12/19/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

typedef NS_ENUM(NSInteger, Status) {
    Status_NotSubmitted,
    Status_Submitted,
    Status_NotApproved,
    Status_Approved
};

typedef NS_ENUM(NSInteger, WeekDay) {
    WeekDay_Monday,
    WeekDay_Tuesday,
    WeekDay_Wednesday,
    WeekDay_Thursday,
    WeekDay_Friday,
    WeekDay_Saturday,
    WeekDay_Sunday,
};

@interface TimesheetWeek : NSObject

@property (nonatomic, assign) NSInteger weekNumber;
@property (nonatomic, assign) Status status;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *hoursPerDay;

@property (nonatomic, copy) NSMutableDictionary<NSString *, NSNumber *> *mon;
@property (nonatomic, copy) NSMutableDictionary<NSString *, NSNumber *> *tue;
@property (nonatomic, copy) NSMutableDictionary<NSString *, NSNumber *> *wed;
@property (nonatomic, copy) NSMutableDictionary<NSString *, NSNumber *> *thu;
@property (nonatomic, copy) NSMutableDictionary<NSString *, NSNumber *> *fri;
@property (nonatomic, copy) NSMutableDictionary<NSString *, NSNumber *> *sat;
@property (nonatomic, copy) NSMutableDictionary<NSString *, NSNumber *> *sun;

@end
