//
//  AppState.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/9/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "User.h"

@interface AppState : NSObject

@property (nonatomic) BOOL signedIn;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, assign) UserType type;
@property (nonatomic, copy) NSString *timesheetKey;
@property (nonatomic, assign) BOOL requiresPhoto;

+ (AppState *)sharedInstance;

- (void)setTypeWithString:(NSString *)typeString;
- (NSString *)stringInPluralWithType;

@end
