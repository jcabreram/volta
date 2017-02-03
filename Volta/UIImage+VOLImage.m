//
//  UIImage+VOLImage.m
//  Volta
//
//  Created by Jonathan Cabrera on 2/3/17.
//  Copyright © 2017 Ksquare Solutions, Inc. All rights reserved.
//

#import "UIImage+VOLImage.h"

@implementation UIImage (VOLImage)

- (UIImage *)resizeWithMaxDimension:(CGFloat)maxDimension
{
    if (fmax(self.size.width, self.size.height) <= maxDimension) {
        return self;
    }
    
    CGFloat aspect = self.size.width / self.size.height;
    CGSize newSize;
    
    if (self.size.width > self.size.height) {
        newSize = CGSizeMake(maxDimension, maxDimension / aspect);
    } else {
        newSize = CGSizeMake(maxDimension * aspect, maxDimension);
    }
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    CGRect newImageRect = CGRectMake(0.0, 0.0, newSize.width, newSize.height);
    [self drawInRect:newImageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
