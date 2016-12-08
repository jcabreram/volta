//
//  NSString+VOLValidation.h
//  Volta
//
//  Created by Jonathan Cabrera on 12/2/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (VOLValidation)

- (BOOL)vol_isValidEmail;
- (BOOL)vol_isValidPassword;
- (BOOL)vol_isStringEmpty;
- (BOOL)vol_isNumber;

@end
