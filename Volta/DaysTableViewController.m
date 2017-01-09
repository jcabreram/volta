//
//  DaysTableViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/15/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "DaysTableViewController.h"
#import "Constants.h"
#import "DayTableViewCell.h"
#import "TimesheetWeek.h"
#import "AppState.h"
#import "DayDetailTableViewController.h"

typedef NS_ENUM (NSInteger, Field) {
    Field_Monday,
    Field_Tuesday,
    Field_Wednesday,
    Field_Thursday,
    Field_Friday,
    Field_Saturday,
    Field_Sunday
};

@interface DaysTableViewController ()

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;

@end

@implementation DaysTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDatabase];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateWeekViewWithStartDate:self.startDate forWeek:self.week];
}

- (void)configureDatabase {
    self.databaseRef = [[FIRDatabase database] reference];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SeguesShowDayDetail]) {
        DayDetailTableViewController *dayDetailController = segue.destinationViewController;
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        WeekDay weekDay = indexPath.row;
        
        dayDetailController.week = self.week;
        dayDetailController.weekDay = weekDay;
    }
}

#pragma mark - Helper methods

- (NSString *)stringWithNameOfDay:(Field)dayField
{
    NSString *weekDay;
    
    switch (dayField) {
        case Field_Monday:
            weekDay = @"monday";
            break;
            
        case Field_Tuesday:
            weekDay = @"tuesday";
            break;
            
        case Field_Wednesday:
            weekDay = @"wednesday";
            break;
            
        case Field_Thursday:
            weekDay = @"thursday";
            break;
            
        case Field_Friday:
            weekDay = @"friday";
            break;
            
        case Field_Saturday:
            weekDay = @"saturday";
            break;
            
        case Field_Sunday:
            weekDay = @"sunday";
            break;
            
        default:
            break;
    }
    
    return weekDay;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    DayTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DayCell" forIndexPath:indexPath];
    
    if (self.startDate) {
        NSInteger row = indexPath.row;
        
        cell.hoursTextField.tag = row;
        
        NSDate *date = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay
                                                                value:row
                                                               toDate:self.startDate
                                                              options:0];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd"];
        
        NSString *dateString = [dateFormatter stringFromDate:date];
        
        cell.dayLabel.text = dateString;
        
        NSNumber *hours = self.week.hoursPerDay[row];
        if ([hours isKindOfClass:[NSNumber class]] && [hours doubleValue] != 0.0) {
            cell.hoursTextField.text = [hours stringValue];
        } else {
            cell.hoursTextField.text = @"";
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat viewHeight = self.view.bounds.size.height;
    return viewHeight / 7;
}


#pragma mark - Weeks collection view delegate

- (void)updateWeekViewWithStartDate:(NSDate *)startDate forWeek:(TimesheetWeek *)week
{
    self.startDate = startDate;
    self.week = week;
    
    NSString *timesheetKey = [AppState sharedInstance].timesheetKey;
    NSString *yearString = [@(week.year) stringValue];
    NSString *weekString = [@(week.weekNumber) stringValue];
    
    [[[[[self.databaseRef child:@"timesheet_details"] child:timesheetKey] child:yearString] child:weekString] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSDictionary *timesheetDetails = snapshot.value;
        
        if ([timesheetDetails isKindOfClass:[NSDictionary class]]) {

            if ([timesheetDetails valueForKeyPath:@"monday.time"]) {
                week.hoursPerDay[0] = [timesheetDetails valueForKeyPath:@"monday.time"];
            }
            if ([timesheetDetails valueForKeyPath:@"tuesday.time"]) {
                week.hoursPerDay[1] = [timesheetDetails valueForKeyPath:@"tuesday.time"];
            }
            if ([timesheetDetails valueForKeyPath:@"wednesday.time"]) {
                week.hoursPerDay[2] = [timesheetDetails valueForKeyPath:@"wednesday.time"];
            }
            if ([timesheetDetails valueForKeyPath:@"thursday.time"]) {
                week.hoursPerDay[3] = [timesheetDetails valueForKeyPath:@"thursday.time"];
            }
            if ([timesheetDetails valueForKeyPath:@"friday.time"]) {
                week.hoursPerDay[4] = [timesheetDetails valueForKeyPath:@"friday.time"];
            }
            if ([timesheetDetails valueForKeyPath:@"saturday.time"]) {
                week.hoursPerDay[5] = [timesheetDetails valueForKeyPath:@"saturday.time"];
            }
            if ([timesheetDetails valueForKeyPath:@"sunday.time"]) {
                week.hoursPerDay[6] = [timesheetDetails valueForKeyPath:@"sunday.time"];
            }
    
            if ([timesheetDetails valueForKeyPath:@"monday.projects"]) {
                week.mon = [[timesheetDetails valueForKeyPath:@"monday.projects"] mutableCopy];
            }
            if ([timesheetDetails valueForKeyPath:@"tuesday.projects"]) {
                week.tue = [[timesheetDetails valueForKeyPath:@"tuesday.projects"] mutableCopy];
            }
            if ([timesheetDetails valueForKeyPath:@"wednesday.projects"]) {
                week.wed = [[timesheetDetails valueForKeyPath:@"wednesday.projects"] mutableCopy];
            }
            if ([timesheetDetails valueForKeyPath:@"thursday.projects"]) {
                week.thu = [[timesheetDetails valueForKeyPath:@"thursday.projects"] mutableCopy];
            }
            if ([timesheetDetails valueForKeyPath:@"friday.projects"]) {
                week.fri = [[timesheetDetails valueForKeyPath:@"friday.projects"] mutableCopy];
            }
            if ([timesheetDetails valueForKeyPath:@"saturday.projects"]) {
                week.sat = [[timesheetDetails valueForKeyPath:@"saturday.projects"] mutableCopy];
            }
            if ([timesheetDetails valueForKeyPath:@"sunday.projects"]) {
                week.sun = [[timesheetDetails valueForKeyPath:@"sunday.projects"] mutableCopy];
            }
        }
        
        [self.tableView reloadData];
        
        [self.delegate updateAllocatedHoursWithNumber:self.week.allocatedHours];
    }];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    UITableViewCell *containerCell = (UITableViewCell *)[[textField superview] superview];
    
    if ([containerCell isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:containerCell];
        NSInteger row = indexPath.row;
        
        NSString *nameOfDay = [self stringWithNameOfDay:row];
        NSNumber *hoursOfDay = @([textField.text doubleValue]);
        
        [[[[[[[self.databaseRef child:@"timesheet_details"] child:[AppState sharedInstance].timesheetKey] child:[@(self.week.year) stringValue]] child:[@(self.week.weekNumber) stringValue]] child:nameOfDay] child:@"time"] setValue:hoursOfDay];
        
        self.week.hoursPerDay[row] = hoursOfDay;
        
        // Update allocated hours label in timesheets VC
        
        [self.delegate updateAllocatedHoursWithNumber:self.week.allocatedHours];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Allow backspace
    if (!string.length) {
        return YES;
    }
    
    if ([string rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789."].invertedSet].location != NSNotFound) {
        return NO;
    }
    
    NSString *proposedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (proposedText.length > 4) {
        return NO;
    }
    
    NSArray *separatedByPeriod = [proposedText componentsSeparatedByString:@"."];
    if ([separatedByPeriod count] > 2 ) {
        return NO;
    }
    
    return YES;
}

@end
