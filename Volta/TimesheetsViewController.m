//
//  TimesheetsViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/10/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "TimesheetsViewController.h"
#import "Constants.h"
#import "WeeksCollectionViewController.h"
#import "DaysTableViewController.h"
#import "AppState.h"
#import "TimesheetWeek.h"

@interface TimesheetsViewController ()

@property (nonatomic, strong) WeeksCollectionViewController *weeksVC;
@property (nonatomic, strong) DaysTableViewController *daysVC;

@property (weak, nonatomic) IBOutlet UILabel *allocatedHoursLabel;

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;

@end

@implementation TimesheetsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDatabase];
}

- (void)configureDatabase {
    self.databaseRef = [[FIRDatabase database] reference];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueName = segue.identifier;
    
    if ([segueName isEqualToString:SeguesPresentWeeks]) {
        self.weeksVC = (WeeksCollectionViewController *)segue.destinationViewController;
    } else if ([segueName isEqualToString:SeguesPresentDays]) {
        self.daysVC = (DaysTableViewController *)segue.destinationViewController;
    }
    
    self.weeksVC.delegate = self.daysVC;
    self.weeksVC.actionSheetDelegate = self;
    self.daysVC.delegate = self;
}

- (IBAction)shareButtonPressed:(id)sender {
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Submit week" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [[[[[self.databaseRef child:@"timesheets"]
            child:[AppState sharedInstance].timesheetKey]
           child:[@(self.week.year) stringValue]]
          child:[@(self.week.weekNumber) stringValue]]
         setValue:@(Status_Submitted)];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark - Days table view delegate

- (void)updateAllocatedHoursWithNumber:(NSNumber *)allocatedHours
{
    self.allocatedHoursLabel.text = [allocatedHours stringValue];
}

#pragma mark - Weeks Collection Action Sheet delegate

- (void)chosenWeekChangedToWeek:(TimesheetWeek *)week
{
    self.week = week;
}

@end
