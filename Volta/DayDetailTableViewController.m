//
//  DayDetailTableViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/22/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "DayDetailTableViewController.h"
#import "DayDetailTableViewCell.h"
#import "AppState.h"
#import "NSString+VOLValidation.h"

@interface DayDetailTableViewController ()

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;
@property (nonatomic, assign) FIRDatabaseHandle availableProjectsHandle;

@property (nonatomic, strong) NSMutableDictionary *availableProjects;
@property (nonatomic, strong) NSArray *projectKeys;
@property (nonatomic, assign) NSInteger numberOfProjectsShown;
@property (nonatomic, strong) NSMutableDictionary *dayProjects;

@end

@implementation DayDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    TimesheetWeek *week = self.week;
    self.dayProjects = [week projectsForDay:self.weekDay];
    
    NSDate *startOfTheWeek = week.startingDate;
    
    NSDate *date = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay
                                                            value:self.weekDay
                                                           toDate:startOfTheWeek
                                                          options:0];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE MMM d"];
    
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    self.navigationItem.title = [NSString stringWithFormat:@"Activities for %@", dateString];
    
    self.availableProjects = [[NSMutableDictionary alloc] init];
    self.projectKeys = [self.dayProjects allKeys];
    self.numberOfProjectsShown = [self.dayProjects count] + 1;
    
    [self configureDatabase];
}

- (void)configureDatabase
{
    self.databaseRef = [[FIRDatabase database] reference];
    
    self.availableProjectsHandle = [[self.databaseRef child:@"projects"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSDictionary<NSString *, NSString *> *childDict = snapshot.value;
        id expectedNameString = childDict[@"name"];
        id expectedKeyString = snapshot.key;
        if (expectedNameString != nil && [expectedNameString isKindOfClass:[NSString class]] && [expectedKeyString isKindOfClass:[NSString class]]) {
            self.availableProjects[(NSString *)expectedKeyString] = expectedNameString;
            
            [self.tableView reloadData];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self updateProjects];
    
    NSString *timesheetKey = [AppState sharedInstance].timesheetKey;
    
    // Update the list of projects for the week
    [[[[[[[self.databaseRef
         child:@"timesheet_details"]
        child:timesheetKey]
       child:[@(self.week.year) stringValue]]
      child:[@(self.week.weekNumber) stringValue]]
      child:[self stringWithNameOfDay:self.weekDay]]
     child:@"projects"] setValue:self.dayProjects];
    
    // Update the total hours for the week
    [[[[[[[self.databaseRef
           child:@"timesheet_details"]
          child:timesheetKey]
         child:[@(self.week.year) stringValue]]
        child:[@(self.week.weekNumber) stringValue]]
       child:[self stringWithNameOfDay:self.weekDay]]
      child:@"time"] setValue:[self sumOfProjectHours]];
}

- (void)updateProjects
{
    [self.dayProjects removeAllObjects];
    
    for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:0]; ++i) {
        NSString *projectName = [self textEnteredInRow:i];
        NSArray *projectsKeys = [self.availableProjects allKeysForObject:projectName];
        
        if ([projectsKeys count] > 0) {
            NSString *projectKey = [projectsKeys firstObject];
            self.dayProjects[projectKey] = [self hoursEnteredInRow:i];
        }
    }
}

- (void)dealloc
{
    [[self.databaseRef child:@"projects"] removeObserverWithHandle:self.availableProjectsHandle];
}

#pragma mark - Helper methods

- (NSString *)textEnteredInRow:(NSInteger)row
{
    DayDetailTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    
    return cell.projectField.text;
}

- (NSNumber *)hoursEnteredInRow:(NSInteger)row
{
    DayDetailTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    
    return @([cell.hoursField.text doubleValue]);
}

- (NSNumber *)sumOfProjectHours
{
    double sum = 0.0;
    
    for (NSNumber *projectHours in [self.dayProjects allValues]) {
        if ([projectHours isKindOfClass:[NSNumber class]]) {
            sum += [projectHours doubleValue];
        }
    }
    
    return @(sum);
}

- (NSString *)stringWithNameOfDay:(WeekDay)dayIndex
{
    NSString *weekDay;
    
    switch (dayIndex) {
        case WeekDay_Monday:
            weekDay = @"monday";
            break;
            
        case WeekDay_Tuesday:
            weekDay = @"tuesday";
            break;
            
        case WeekDay_Wednesday:
            weekDay = @"wednesday";
            break;
            
        case WeekDay_Thursday:
            weekDay = @"thursday";
            break;
            
        case WeekDay_Friday:
            weekDay = @"friday";
            break;
            
        case WeekDay_Saturday:
            weekDay = @"saturday";
            break;
            
        case WeekDay_Sunday:
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
    return self.numberOfProjectsShown;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = indexPath.row;
    
    DayDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DayDetailCell" forIndexPath:indexPath];
    
    MLPAutoCompleteTextField *projectField = cell.projectField;
    projectField.autoCompleteTableAppearsAsKeyboardAccessory = YES;
    
    // Parent correction
    projectField.autoCompleteParentView = self.view;
    
    // Offset correction
    CGPoint pt = [projectField convertPoint:CGPointMake(0, projectField.frame.origin.y) toView:self.view];
    projectField.autoCompleteTableOriginOffset = CGSizeMake(0, pt.y);
    
    if ([self.projectKeys count] > row) {
        NSString *currentProjectKey = self.projectKeys[row];
        
        projectField.text = self.availableProjects[currentProjectKey];
        cell.hoursField.text = [self.dayProjects[currentProjectKey] stringValue];
    }
    
    return cell;
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)[[textField superview] superview]];
    
    NSInteger row = indexPath.row;
    
    if (self.numberOfProjectsShown < row + 2) {
        self.numberOfProjectsShown = row + 2;
        [self.tableView reloadData];
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)[[textField superview] superview]];
    
    NSInteger row = indexPath.row;
    
    DayDetailTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    
    cell.hoursField.text = @"";
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.tag == 2) {
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
    }
    
    return YES;
}

#pragma mark - MLPAutoCompleteTextField delegate

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
 possibleCompletionsForString:(NSString *)string
            completionHandler:(void (^)(NSArray *))handler
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        NSArray *completions = [self.availableProjects allValues];
        handler(completions);
    });
}


@end
