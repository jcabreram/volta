//
//  Project.h
//  Volta
//
//  Created by Jonathan Cabrera on 12/7/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Project : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *organization;
@property (nonatomic, copy) NSString *companyKey;
@property (nonatomic, assign) NSInteger totalDuration;

- (instancetype)init;
- (instancetype)initWithKey:(NSString *)key
                       name:(NSString *)name
               organization:(NSString *)organization
                 companyKey:(NSString *)companyKey
              totalDuration:(NSInteger)totalDuration;

@end
