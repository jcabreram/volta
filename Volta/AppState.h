//
//  AppState.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/9/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//


@interface AppState : NSObject

+ (AppState *)sharedInstance;

@property (nonatomic) BOOL signedIn;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSURL *photoURL;

@end
