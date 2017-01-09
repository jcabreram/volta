//
//  WeeksCollectionViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/15/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

@class TimesheetWeek;

@protocol WeeksCollectionViewControllerDelegate <NSObject>

- (void)updateWeekViewWithStartDate:(NSDate *)startDate
                            forWeek:(TimesheetWeek *)week;

@end

@protocol WeeksCollectionViewControllerActionSheetDelegate <NSObject>

- (void)chosenWeekChangedToWeek:(TimesheetWeek *)week;

@end

@interface WeeksCollectionViewController : UICollectionViewController

@property (nonatomic, weak) id<WeeksCollectionViewControllerDelegate> delegate;
@property (nonatomic, weak) id<WeeksCollectionViewControllerActionSheetDelegate> actionSheetDelegate;

@end
