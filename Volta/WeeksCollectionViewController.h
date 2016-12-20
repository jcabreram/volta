//
//  WeeksCollectionViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/15/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "TimesheetWeek.h"

@protocol WeeksCollectionViewControllerDelegate <NSObject>

- (void)updateWeekViewWithStartDate:(NSDate *)startDate
                      forWeekNumber:(NSInteger)weekNumber;

@end

@interface WeeksCollectionViewController : UICollectionViewController

@property (nonatomic, weak) id<WeeksCollectionViewControllerDelegate> delegate;

@end
