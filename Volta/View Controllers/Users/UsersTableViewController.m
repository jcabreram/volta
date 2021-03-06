//
//  UsersTableViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/29/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//

typedef NS_ENUM(NSInteger, UserSection) {
    UserSection_Employees,
    UserSection_Managers,
    UserSection_Admins
};

#import "UsersTableViewController.h"
#import "UserDetailTableViewController.h"
#import "Constants.h"
#import "User.h"
#import "AppState.h"
#import "UIImage+VOLImage.h"
#import "UserCell.h"
#import "UIColor+VOLcolors.h"

@interface UsersTableViewController ()

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;
@property (nonatomic, assign) FIRDatabaseHandle referenceHandle;
@property (nonatomic, strong) NSMutableArray<FIRDataSnapshot *> *employees;
@property (nonatomic, strong) NSMutableArray<FIRDataSnapshot *> *managers;
@property (nonatomic, strong) NSMutableArray<FIRDataSnapshot *> *admins;
@property (nonatomic, strong) User *selectedUser;

@property (nonatomic, assign) FIRDatabaseHandle availableCompaniesHandle;
@property (nonatomic, strong) NSMutableDictionary *availableCompanies;

@property (nonatomic, assign) FIRDatabaseHandle employeesStatusHandle;
@property (nonatomic, strong) NSMutableDictionary *employeesStatus;
@property (nonatomic, strong) NSString *currentYearString;
@property (nonatomic, strong) NSString *pastWeekString;

@end

@implementation UsersTableViewController

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Change title to Employees if manager
    UserType loggedInUserType = [AppState sharedInstance].type;
    if (loggedInUserType == UserType_Manager) {
        self.title = @"Team Members";
        self.navigationController.toolbarHidden = YES;
    }
    
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Change the navigation bar color to gradient
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageLayerForGradientBackgroundWithBounds:self.navigationController.navigationBar.bounds] forBarMetrics:UIBarMetricsDefault];
    
    self.employees = [[NSMutableArray alloc] init];
    self.managers = [[NSMutableArray alloc] init];
    self.admins = [[NSMutableArray alloc] init];
    
    self.availableCompanies = [[NSMutableDictionary alloc] init];
    
    self.employeesStatus = [[NSMutableDictionary alloc] init];
    
    // Current week of the year
    NSDate *today = [NSDate date];
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    cal.firstWeekday = 2; // Monday
    
    NSDateComponents *currentDateComponents = [cal components:(NSCalendarUnitWeekOfYear | NSCalendarUnitYearForWeekOfYear) fromDate:today];
    NSInteger currentYear = [currentDateComponents yearForWeekOfYear];
    self.currentYearString = [@(currentYear) stringValue];
    NSInteger currentWeek = [currentDateComponents weekOfYear];
    NSInteger pastWeek = currentWeek - 2;
    self.pastWeekString = [@(pastWeek) stringValue];
    
    [self configureDatabase];
}

- (void)resetPresentingController {
    self.selectedUser = [[User alloc] init];
    
    // Clear the users data and reload the table to empty it
    [self.employees removeAllObjects];
    [self.managers removeAllObjects];
    [self.admins removeAllObjects];
    
    // Load the users data back from the database
    [[self.databaseRef child:@"projects"] removeObserverWithHandle:self.referenceHandle];
    [self configureDatabase];
    
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *navigationController = segue.destinationViewController;
    
    // Change the navigation bar color to gradient
    [navigationController.navigationBar setBackgroundImage:[UIImage imageLayerForGradientBackgroundWithBounds:self.navigationController.navigationBar.bounds] forBarMetrics:UIBarMetricsDefault];
    
    UserDetailTableViewController *userDetailController = navigationController.childViewControllers[0];
    
    userDetailController.delegate = self;
    
    if (!self.selectedUser) {
        self.selectedUser = [[User alloc] init];
    }
    
    if ([segue.identifier isEqualToString:SeguesAddManager]) {
        self.selectedUser.type = UserType_Manager;
    } else if ([segue.identifier isEqualToString:SeguesAddEmployee]) {
        self.selectedUser.type = UserType_Employee;
    } else if ([segue.identifier isEqualToString:SeguesAddAdmin]) {
        self.selectedUser.type = UserType_Admin;
    } else if ([segue.identifier isEqualToString:SeguesShowUserDetail]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        
        FIRDataSnapshot *userSnapshot;
        
        switch (indexPath.section) {
            case UserSection_Employees:
                userSnapshot = self.employees[indexPath.row];
                break;
            case UserSection_Managers:
                userSnapshot = self.managers[indexPath.row];
                break;
            case UserSection_Admins:
                userSnapshot = self.admins[indexPath.row];
                break;
            default:
                userSnapshot = self.employees[indexPath.row];
                break;
        }
        
        NSDictionary *user = userSnapshot.value;
        NSString *userKey = userSnapshot.key;
        
        self.selectedUser = [[User alloc] initWithKey:userKey
                                            firstName:user[@"first_name"]
                                             lastName:user[@"last_name"]
                                                email:user[@"email"]
                                             password:user[@"first_name"]
                                            createdAt:[NSDate dateWithTimeIntervalSince1970:[user[@"created_at"] doubleValue]]
                                                 type:[User userTypeFromString:user[@"type"]]
                                            employees:user[@"employees"]
                                             managers:user[@"managers"]
                                           companyKey:user[@"company"]
                                            timesheet:user[@"timesheet"]
                                             projects:user[@"projects"]];
        
        if (user[@"requires_photo"]) {
            NSNumber *requiresPhotoNumber = user[@"requires_photo"];
            if ([requiresPhotoNumber isKindOfClass:[NSNumber class]]) {
                self.selectedUser.requiresPhoto = [requiresPhotoNumber boolValue];
            }
        }
    }
    
    userDetailController.user = self.selectedUser;
}

#pragma mark - Database

- (void)configureDatabase {
    AppState *state = [AppState sharedInstance];
    UserType loggedInUserType = state.type;
    NSString *userID = state.userID;

    self.databaseRef = [[FIRDatabase database] reference];
    self.referenceHandle = [[_databaseRef child:@"users"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *user = snapshot.value;
            if (loggedInUserType == UserType_Manager) {
                NSDictionary *managers = user[@"managers"];
                if (managers[userID]) {
                    [self.employees addObject:snapshot];
                    [self addStatusForUserWithID:snapshot.key andTimesheet:user[@"timesheet"]];
                }
            } else {
                NSString *userType = user[@"type"];
                if ([userType isEqualToString:@"admin"]) {
                    [self.admins addObject:snapshot];
                } else if ([userType isEqualToString:@"manager"]) {
                    [self.managers addObject:snapshot];
                } else if ([userType isEqualToString:@"employee"]) {
                    [self.employees addObject:snapshot];
                    [self addStatusForUserWithID:snapshot.key andTimesheet:user[@"timesheet"]];
                }
            }
            [self sortUserArrays];
            [self.tableView reloadData];
        }
    }];
    
    self.availableCompaniesHandle = [[self.databaseRef child:@"companies"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSDictionary<NSString *, NSString *> *childDict = snapshot.value;
        id expectedNameString = childDict[@"name"];
        id expectedKeyString = snapshot.key;
        if (expectedNameString != nil && [expectedNameString isKindOfClass:[NSString class]] && [expectedKeyString isKindOfClass:[NSString class]]) {
            self.availableCompanies[(NSString *)expectedKeyString] = expectedNameString;
        }
    }];
}

- (void)addStatusForUserWithID:(NSString *)userID andTimesheet:(NSString *)timesheetKey
{
    self.employeesStatusHandle = [[[[[self.databaseRef child:@"timesheets"] child:timesheetKey] child:self.currentYearString] child:self.pastWeekString] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        if (snapshot.exists) {
            self.employeesStatus[userID] = snapshot.value;
            [self.tableView reloadData];
        }
    }];
}

- (void)dealloc {
    [[self.databaseRef child:@"users"] removeObserverWithHandle:self.referenceHandle];
    [[self.databaseRef child:@"companies"] removeObserverWithHandle:self.availableCompaniesHandle];
    [[self.databaseRef child:@"timesheets"] removeObserverWithHandle:self.employeesStatusHandle];
}

- (void)sortUserArrays
{
    NSSortDescriptor *firstNameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"value.first_name" ascending:YES selector:@selector(localizedStandardCompare:)];
    self.employees = [[self.employees sortedArrayUsingDescriptors:@[firstNameSortDescriptor]] mutableCopy];
    self.managers = [[self.managers sortedArrayUsingDescriptors:@[firstNameSortDescriptor]] mutableCopy];
    self.admins = [[self.admins sortedArrayUsingDescriptors:@[firstNameSortDescriptor]] mutableCopy];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    AppState *state = [AppState sharedInstance];
    UserType loggedInUserType = state.type;
    
    if (loggedInUserType == UserType_Admin) {
        return 3;
    } else {
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    AppState *state = [AppState sharedInstance];
    UserType loggedInUserType = state.type;
    
    if (loggedInUserType == UserType_Admin) {
        switch (section) {
            case UserSection_Employees:
                return @"Employees";
            case UserSection_Managers:
                return @"Managers";
            case UserSection_Admins:
                return @"Admins";
            default:
                return 0;
        }
    } else {
        return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case UserSection_Employees:
            return [self.employees count];
        case UserSection_Managers:
            return [self.managers count];
        case UserSection_Admins:
            return [self.admins count];
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    
    FIRDataSnapshot *userSnapshot;
    
    switch (indexPath.section) {
        case UserSection_Employees:
            userSnapshot = _employees[indexPath.row];
            break;
        case UserSection_Managers:
            userSnapshot = _managers[indexPath.row];
            break;
        case UserSection_Admins:
            userSnapshot = _admins[indexPath.row];
            break;
        default:
            userSnapshot = _employees[indexPath.row];
            break;
    }
    NSDictionary<NSString *, NSString *> *user = userSnapshot.value;
    NSString *userKey = userSnapshot.key;
    
    NSString *firstName = user[@"first_name"];
    NSString *lastName = user[@"last_name"];
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    cell.nameLabel.text = fullName;
    
    if (indexPath.section != UserSection_Admins) {
        if (user[@"company"]) {
            NSString *companyKey = user[@"company"];
            cell.companyLabel.text = self.availableCompanies[companyKey];
        }
    } else {
        cell.companyLabel.text = @"";
    }
    
    if (indexPath.section != UserSection_Employees) {
        cell.dotIndicatorLabel.text = @"";
        cell.dotIndicatorLabelConstraint.constant = 0.0;
    } else {
        cell.dotIndicatorLabel.text = @"●";
        cell.dotIndicatorLabelConstraint.constant = 16.0;
        
        Status userStatus = [self.employeesStatus[userKey] integerValue];
        
        switch (userStatus) {
            case Status_NotSubmitted:
                cell.dotIndicatorLabel.textColor = [UIColor notSubmittedPastStatusColor];
                break;
            case Status_Submitted:
                cell.dotIndicatorLabel.textColor = [UIColor submittedStatusColor];
                break;
            case Status_Approved:
                cell.dotIndicatorLabel.textColor = [UIColor approvedStatusColor];
                break;
            case Status_NotApproved:
                cell.dotIndicatorLabel.textColor = [UIColor notApprovedStatusColor];
                break;
            default:
                cell.dotIndicatorLabel.textColor = [UIColor notSubmittedPastStatusColor];
                break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self performSegueWithIdentifier:SeguesShowUserDetail sender:cell];
}

@end
