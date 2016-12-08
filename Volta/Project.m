//
//  Project.m
//  Volta
//
//  Created by Jonathan Cabrera on 12/7/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "Project.h"

@implementation Project

- (instancetype)init
{
    return [self initWithKey:@""
                        name:@""
                organization:@""
                  companyKey:@""
             defaultDuration:0];
}

- (instancetype)initWithKey:(NSString *)key
                       name:(NSString *)name
               organization:(NSString *)organization
                 companyKey:(NSString *)companyKey
            defaultDuration:(NSInteger)defaultDuration
{
    self = [super init];
    
    if (self) {
        _key = key;
        _name = name;
        _organization = organization;
        _companyKey = companyKey;
        _defaultDuration = defaultDuration;
    }
    
    return self;
}

@end
