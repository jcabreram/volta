//
//  User.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/30/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "User.h"

@implementation User

- (instancetype)init
{
    return [self initWithFirstName:@""
                          lastName:@""
                             email:@""
                          password:@""
                         createdAt:[NSDate date]
                              type:UserType_Employee
                         employees:[NSMutableDictionary new]
                          managers:[NSMutableDictionary new]
                        companyKey:@""
                         timesheet:@""
                          projects:[NSMutableDictionary new]];
    
}

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
                         projects:(NSMutableDictionary<NSString *, NSNumber *> *)projects
{
    self = [super init];
    
    if (self) {
        _firstName = firstName;
        _lastName = lastName;
        _email = email;
        _password = password;
        _createdAt = createdAt;
        _type = type;
        _employees = employees;
        _managers = managers;
        _companyKey = companyKey;
        _timesheet = timesheet;
        _projects = projects;
    }
    
    return self;
    
}

- (NSString *)userTypeString
{
    switch (self.type) {
        case UserType_Admin:
            return @"admin";
            break;
        case UserType_Manager:
            return @"manager";
            break;
        case UserType_Employee:
            return @"employee";
            break;
        default:
            return @"";
            break;
    }
}

@end
