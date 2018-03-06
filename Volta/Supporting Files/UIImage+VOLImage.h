//
//  UIImage+VOLImage.h
//  Volta
//
//  Created by Jonathan Cabrera on 2/3/17.
//  Copyright © 2017 Jonathan Cabrera All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (VOLImage)

- (UIImage *)resizeWithMaxDimension:(CGFloat)maxDimension;
+ (UIImage *)imageLayerForGradientBackgroundWithBounds:(CGRect)bounds;

@end
