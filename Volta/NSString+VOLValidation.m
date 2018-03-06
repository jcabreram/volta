//
//  NSString+VOLValidation.m
//  Volta
//
//  Created by Jonathan Cabrera on 12/2/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//

#import "NSString+VOLValidation.h"

@implementation NSString (VOLValidation)

- (BOOL)vol_isValidEmail
{
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

- (BOOL)vol_isValidPassword
{
    if ( [self length] < 6 || [self length] > 32 ) return NO;  // between 6 and 32 characters
    NSRange range;
    range = [self rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
    if ( !range.length ) return NO;  // with letter
    range = [self rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
    if ( !range.length )  return NO;  // with number
    return YES;
}

- (BOOL)vol_isStringEmpty
{
    if (self == nil || [self length] == 0) { //string is empty or nil
        return YES;
    }
    
    if (![[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        //string is all whitespace
        return YES;
    }
    
    return NO;
}

- (BOOL)vol_isNumber
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
    BOOL isNumeric = [scanner scanInteger:NULL] && [scanner isAtEnd];
    
    return isNumeric;
}

@end
