//
//  GlobalVars.m
//  Volta
//
//  Created by Sanchez De La Pena, Julian on 11/21/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "GlobalVars.h"

static NSUserDefaults *_userDefaults = nil;

static NSString *const kCompleteUser = @"persistCompleteUser";


@implementation GlobalVars

+ (instancetype)sharedInstance {
    static GlobalVars *_sharedInstance = nil;
    
    if (_sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _sharedInstance = [[GlobalVars alloc] init];
            _userDefaults = [NSUserDefaults standardUserDefaults];
        });
    }
    
    return _sharedInstance;
}

- (NSString *)completeUsername {
    return [_userDefaults stringForKey:kCompleteUser];
}

- (void)setCompleteUsername:(NSString *)completeUsername {
    [_userDefaults setObject:completeUsername forKey:kCompleteUser];
    [_userDefaults synchronize];
}

@end
