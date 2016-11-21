//
//  GlobalVars.h
//  Volta
//
//  Created by Sanchez De La Pena, Julian on 11/21/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlobalVars : NSObject

@property (nonatomic, strong) NSString *completeUsername;

+ (instancetype)sharedInstance;

@end
