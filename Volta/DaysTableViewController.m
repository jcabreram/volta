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

@interface DaysTableViewController ()

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

@end
