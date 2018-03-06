//
//  UIColor+VOLcolors.m
//  Volta
//
//  Created by Jonathan Cabrera on 12/21/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//

#import "UIColor+VOLcolors.h"

@implementation UIColor (VOLcolors)

+ (UIColor *)notSubmittedStatusColor {
    return [UIColor colorWithRed:0.58 green:0.60 blue:0.60 alpha:1.0];
}

+ (UIColor *)notSubmittedPastStatusColor {
    return [UIColor colorWithRed:0.93 green:0.53 blue:0.06 alpha:1.0];
}

+ (UIColor *)submittedStatusColor {
    return [UIColor colorWithRed:0.00 green:0.56 blue:0.99 alpha:1.0];
}

+ (UIColor *)notApprovedStatusColor {
    return [UIColor colorWithRed:0.99 green:0.00 blue:0.00 alpha:1.0];
}

+ (UIColor *)approvedStatusColor {
    return [UIColor colorWithRed:0.33 green:0.78 blue:0.42 alpha:1.0];
}

+ (UIColor *)voltaBlue
{
    return [UIColor colorWithRed:0.18 green:0.51 blue:0.74 alpha:1.0];
}

+ (UIColor *)darkerBlue
{
    return  [UIColor colorWithRed:0.02 green:0.24 blue:0.40 alpha:1.0];
}

+ (UIColor *)lighterBlue
{
    return [UIColor colorWithRed:0.25 green:0.65 blue:0.95 alpha:1.0];
}

@end
