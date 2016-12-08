//
//  Project.h
//  Volta
//
//  Created by Jonathan Cabrera on 12/7/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Project : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *organization;
@property (nonatomic, copy) NSString *companyKey;
@property (nonatomic, assign) NSInteger defaultDuration;

- (instancetype)init;
- (instancetype)initWithKey:(NSString *)key
                       name:(NSString *)name
               organization:(NSString *)organization
                 companyKey:(NSString *)companyKey
            defaultDuration:(NSInteger)defaultDuration;

@end
