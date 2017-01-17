//
//  DayDetailTableViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/22/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "TimesheetWeek.h"
#import "MLPAutoCompleteTextField.h"

@interface DayDetailTableViewController : UITableViewController <UITextFieldDelegate, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate>

@property (nonatomic, strong) TimesheetWeek *week;
@property (nonatomic, assign) WeekDay weekDay;

@end
