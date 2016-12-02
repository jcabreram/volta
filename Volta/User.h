//
//  User.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/30/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

typedef NS_ENUM (NSInteger, UserType) {
    UserType_Admin,
    UserType_Manager,
    UserType_Employee
};

@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, assign) UserType type;
@property (nonatomic, copy) NSMutableDictionary<NSString *, NSNumber *> *employees;
@property (nonatomic, copy) NSMutableDictionary<NSString *, NSNumber *> *managers;
@property (nonatomic, copy) NSString *companyKey;
@property (nonatomic, copy) NSString *timesheet;
@property (nonatomic, copy) NSMutableDictionary<NSString *, NSNumber *> *projects;

- (instancetype)init;
- (instancetype)initWithFirstName:(NSString *)firstName
                         lastName:(NSString *)lastName
                            email:(NSString *)email
                         password:(NSString *)password
                        createdAt:(NSDate *)createdAt
                             type:(UserType)type
                        employees:(NSMutableDictionary<NSString *, NSNumber *> *)employees
                         managers:(NSMutableDictionary<NSString *, NSNumber *> *)managers
                       companyKey:(NSString *)companyKey
                        timesheet:(NSString *)timesheet
                         projects:(NSMutableDictionary<NSString *, NSNumber *> *)projects;

- (NSString *)userTypeString;

+ (UserType)userTypeFromString:(NSString *)str;

@end
