//
//  AppState.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/9/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppState : NSObject

+ (AppState *)sharedInstance;

@property (nonatomic) BOOL signedIn;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSURL *photoURL;

@end
