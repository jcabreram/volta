//
//  TimesheetsViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/10/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "DaysTableViewController.h"
#import "WeeksCollectionViewController.h"

@interface TimesheetsViewController : UIViewController <DaysTableViewControllerDelegate, WeeksCollectionViewControllerActionSheetDelegate>

@property (nonatomic, strong) TimesheetWeek *week;

- (void)chosenWeekChangedToWeek:(TimesheetWeek *)week;

@end
