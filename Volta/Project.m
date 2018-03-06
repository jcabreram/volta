//
//  Project.m
//  Volta
//
//  Created by Jonathan Cabrera on 12/7/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//

#import "Project.h"

@implementation Project

- (instancetype)init
{
    return [self initWithKey:@""
                        name:@""
                organization:@""
                  companyKey:@""
             totalDuration:0];
}

- (instancetype)initWithKey:(NSString *)key
                       name:(NSString *)name
               organization:(NSString *)organization
                 companyKey:(NSString *)companyKey
              totalDuration:(NSInteger)totalDuration
{
    self = [super init];
    
    if (self) {
        _key = key;
        _name = name;
        _organization = organization;
        _companyKey = companyKey;
        _totalDuration = totalDuration;
    }
    
    return self;
}

@end
