//
//  DaysTableViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/15/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "WeeksCollectionViewController.h"

@class TimesheetWeek;

@interface DaysTableViewController : UITableViewController <WeeksCollectionViewControllerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) TimesheetWeek *week;
@property (nonatomic, assign) NSInteger year;

@end
