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

@property (nonatomic, strong) NSMutableArray *hoursByDay;

@end

@implementation DaysTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
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
    
    // Configure the cell...
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat viewHeight = self.view.bounds.size.height;
    return viewHeight / 7;
}


#pragma mark - Weeks collection view delegate

- (void)updateWeekViewWithStartDate:(NSDate *)startDate forWeekNumber:(NSInteger)weekNumber
{
    self.startDate = startDate;
    self.weekNumber = weekNumber;
    
    [self.tableView reloadData];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
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
