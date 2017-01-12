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
#import "ActionSheetPicker.h"

@interface TimesheetsViewController ()

@property (nonatomic, strong) WeeksCollectionViewController *weeksVC;
@property (nonatomic, strong) DaysTableViewController *daysVC;

@property (weak, nonatomic) IBOutlet UILabel *allocatedHoursLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectEmployeeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIView *darkOverlay;

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;
@property (nonatomic, strong) NSMutableDictionary *availableEmployees;

@end

@implementation TimesheetsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UserType currentUserType = [AppState sharedInstance].type;
    if (currentUserType == UserType_Employee) {
        self.navigationController.toolbarHidden = YES;
        [self.darkOverlay removeFromSuperview];
    }
    
    [self configureDatabase];
}

- (void)configureDatabase {
    self.databaseRef = [[FIRDatabase database] reference];
    
    NSString *currentUserID = [AppState sharedInstance].userID;
    UserType currentUserType = [AppState sharedInstance].type;
    
    if (currentUserType == UserType_Admin) {
        [[[self.databaseRef child:@"employees"]
          child:@"members"]
         observeSingleEventOfType:FIRDataEventTypeValue
         withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
             if (snapshot.exists) {
                 self.availableEmployees = snapshot.value;
                 
                 for (NSString *userKey in self.availableEmployees) {
                     [[[self.databaseRef child:@"users"] child:userKey] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                         if (snapshot.exists) {
                             NSString *firstName = snapshot.value[@"first_name"];
                             NSString *lastName = snapshot.value[@"last_name"];
                             NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                             self.availableEmployees[userKey] = fullName;
                         } else {
                             [self.availableEmployees removeObjectForKey:userKey];
                         }
                     }];
                 }
             }
         }];
    } else if (currentUserType == UserType_Manager) {
        [[[[self.databaseRef child:@"users"]
           child:currentUserID]
          child:@"employees"]
         observeSingleEventOfType:FIRDataEventTypeValue
         withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
             if (snapshot.exists) {
                 self.availableEmployees = snapshot.value;
                 
                 for (NSString *userKey in self.availableEmployees) {
                     [[[self.databaseRef child:@"users"] child:userKey] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                         if (snapshot.exists) {
                             NSString *firstName = snapshot.value[@"first_name"];
                             NSString *lastName = snapshot.value[@"last_name"];
                             NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                             self.availableEmployees[userKey] = fullName;
                         } else {
                             [self.availableEmployees removeObjectForKey:userKey];
                         }
                     }];
                 }
             }
         }];
    }
    
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
    
    AppState *state = [AppState sharedInstance];
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (state.type == UserType_Employee) {
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Submit Week" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self changeWeekToStatus:Status_Submitted];
        }]];
        
    } else if (state.type == UserType_Admin || state.type == UserType_Manager) {
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Approve" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self changeWeekToStatus:Status_Approved];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Don't Approve" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self changeWeekToStatus:Status_NotApproved];
        }]];
    }
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)changeWeekToStatus:(Status)status
{
    [[[[[self.databaseRef child:@"timesheets"]
        child:[AppState sharedInstance].timesheetKey]
       child:[@(self.week.year) stringValue]]
      child:[@(self.week.weekNumber) stringValue]]
     setValue:@(status)];
}

- (IBAction)selectEmployeeButtonPressed:(id)sender {
    NSArray *employeeNames = [self.availableEmployees allValues];
    if (!employeeNames) {
        employeeNames = [[NSArray alloc] init];
    }
    NSArray *orderedEmployeeNames = [employeeNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    ActionSheetStringPicker *picker = [[ActionSheetStringPicker alloc] initWithTitle:@"Select an Employee"
                                                                                rows:orderedEmployeeNames
                                                                    initialSelection:0
                                                                           doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                                                               
                                                                               NSArray *employeeKeys = [self.availableEmployees allKeysForObject:selectedValue];
                                                                               
                                                                               if ([employeeKeys count] > 0) {
                                                                                   NSString *employeeKey = [employeeKeys firstObject];
                                                                                   [self showTimesheetForUserWithID:employeeKey];
                                                                                   
                                                                                   self.selectEmployeeBarButtonItem.title = selectedValue;
                                                                                   [self.darkOverlay removeFromSuperview];
                                                                               }
                                                                           }
                                                                         cancelBlock:nil
                                                                              origin:sender];
    
    [picker showActionSheetPicker];
}

- (void)showTimesheetForUserWithID:(NSString *)userID
{
    AppState *state = [AppState sharedInstance];
    
    [[[self.databaseRef child:@"users"] child:userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSLog(@"");
        if (snapshot.exists) {
            state.timesheetKey = snapshot.value[@"timesheet"];
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationKeysTimesheetDidChange object:nil];
        }
    }];
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
