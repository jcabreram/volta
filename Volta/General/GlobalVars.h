//
//  GlobalVars.h
//  Volta
//
//  Created by Sanchez De La Pena, Julian on 11/21/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//


@interface GlobalVars : NSObject

@property (nonatomic, strong) NSString *completeUsername;

+ (instancetype)sharedInstance;

@end
