//
//  AppState.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/9/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "AppState.h"

@implementation AppState

+ (AppState *)sharedInstance {
    static AppState *sharedMyInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyInstance = [[self alloc] init];
    });
    return sharedMyInstance;
}

- (void)setTypeWithString:(NSString *)typeString
{
    if ([typeString isEqualToString:@"employee"]) {
        self.type = UserType_Employee;
    } else if ([typeString isEqualToString:@"manager"]) {
        self.type = UserType_Manager;
    } else if ([typeString isEqualToString:@"admin"]) {
        self.type = UserType_Admin;
    }
}

- (NSString *)stringInPluralWithType
{
    switch (self.type) {
        case UserType_Employee:
            return @"employees";
            break;
        case UserType_Manager:
            return @"managers";
            break;
        case UserType_Admin:
            return @"admins";
            break;
        default:
            break;
    }
}

@end
