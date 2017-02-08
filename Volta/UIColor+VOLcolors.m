//
//  UIColor+VOLcolors.m
//  Volta
//
//  Created by Jonathan Cabrera on 12/21/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "UIColor+VOLcolors.h"

@implementation UIColor (VOLcolors)

+ (UIColor *)notSubmittedStatusColor {
    return [UIColor colorWithRed:1.00 green:0.92 blue:0.61 alpha:1.0];
}

+ (UIColor *)submittedStatusColor {
    return [UIColor colorWithRed:0.71 green:0.78 blue:0.91 alpha:1.0];
}

+ (UIColor *)notApprovedStatusColor {
    return [UIColor colorWithRed:1.00 green:0.78 blue:0.81 alpha:1.0];
}

+ (UIColor *)approvedStatusColor {
    return [UIColor colorWithRed:0.78 green:0.94 blue:0.81 alpha:1.0];
}

+ (UIColor *)redKsquareColor
{
    return [UIColor colorWithRed:0.80 green:0.20 blue:0.20 alpha:1.0];
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
