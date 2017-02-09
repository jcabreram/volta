//
//  WeekCollectionViewCell.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/15/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

@class TimesheetWeek;

@interface WeekCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *dateRangeLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIView *selectedIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *dotStatusLabel;

@property (nonatomic, assign) NSInteger weekOfYear;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, assign) NSInteger year;

@property (nonatomic, strong) TimesheetWeek *week;

@end
