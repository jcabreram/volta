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
                            forWeek:(TimesheetWeek *)week;
- (void)weekStatusChangedTo:(Status)status;

@end

@protocol WeeksCollectionViewControllerActionSheetDelegate <NSObject>

- (void)chosenWeekChangedToWeek:(TimesheetWeek *)week;
- (void)weekStatusChangedTo:(Status)status;

@end

@interface WeeksCollectionViewController : UICollectionViewController

@property (nonatomic, weak) id<WeeksCollectionViewControllerDelegate> delegate;
@property (nonatomic, weak) id<WeeksCollectionViewControllerActionSheetDelegate> actionSheetDelegate;

@end
