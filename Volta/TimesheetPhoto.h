//
//  TimesheetPhoto.h
//  Volta
//
//  Created by Jonathan Cabrera on 2/10/17.
//  Copyright © 2017 Jonathan Cabrera All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NYTPhotoViewer/NYTPhoto.h>

@interface TimesheetPhoto : NSObject <NYTPhoto>

@property (nonatomic) UIImage *image;
@property (nonatomic) NSData *imageData;
@property (nonatomic) UIImage *placeholderImage;
@property (nonatomic) NSAttributedString *attributedCaptionTitle;
@property (nonatomic) NSAttributedString *attributedCaptionSummary;
@property (nonatomic) NSAttributedString *attributedCaptionCredit;

@end
