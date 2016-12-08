//
//  UserDetailTableViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/29/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "UserDetailTableViewController.h"
#import "User.h"
#import "NSString+VOLValidation.h"
#import "UserDetailCell.h"
#import "Constants.h"
#import "UsersTableViewController.h"
#import "AppState.h"

@import Firebase;

typedef NS_ENUM (NSInteger, InfoField) {
    InfoField_FirstName,
    InfoField_LastName,
    InfoField_Email,
    InfoField_Password,
    InfoField_Company,
    InfoField_Manager
};

@interface UserDetailTableViewController ()

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;
@property (nonatomic, strong) NSMutableArray<FIRDataSnapshot *> *projects;

@end

@implementation UserDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    User *user = self.user;
    
    if (!user) {
        user = [[User alloc] init];
    }
    
    self.projects = [[NSMutableArray alloc] init];
    
    if ([user.key vol_isStringEmpty]) {
        switch (user.type) {
            case UserType_Admin:
                self.navigationItem.title = @"Add admin";
                break;
                
            case UserType_Manager:
                self.navigationItem.title = @"Add manager";
                break;
                
            case UserType_Employee:
                self.navigationItem.title = @"Add employee";
                break;
                
            default:
                break;
        }
    } else {
        NSString *fullName = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
        self.navigationItem.title = fullName;
    }
    
    [self configureDatabase];
}

- (void)configureDatabase {
    _databaseRef = [[FIRDatabase database] reference];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)tappedDoneButton:(id)sender
{
    [self.view endEditing:YES];
    
    if ([self validInput]) {
        
        User *user = self.user;
        
        if ([user.key vol_isStringEmpty]) {
            [[FIRAuth auth] createUserWithEmail:user.email
                                       password:user.password
                                     completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                                         if (error) {
                                             [self presentValidationErrorAlertWithTitle:@"Error"
                                                                                message:error.localizedDescription];
                                             NSLog(@"%@", error.localizedDescription);
                                         } else {
                                             [self updateUserInDatabase];
                                         }
                                     }];
        } else {
            [self updateUserInDatabase];
        }
    }
    
}

- (void)updateUserInDatabase {
    User *user = self.user;
    
    NSString *creatorID = [AppState sharedInstance].userID;
    
    NSString *timesheetKey;
    NSString *userKey;
    
    if ([user.key vol_isStringEmpty]) {
        timesheetKey = [[self.databaseRef child:@"timesheets"] childByAutoId].key;
        userKey = [[self.databaseRef child:@"users"] childByAutoId].key;
    } else {
        timesheetKey = user.timesheet;
        userKey = user.key;
    }
    
    NSDictionary *userDict = @{@"email":user.email,
                               @"first_name":user.firstName,
                               @"last_name":user.lastName,
                               @"created_at":[NSNumber numberWithDouble:[user.createdAt timeIntervalSince1970]],
                               @"created_by":creatorID,
                               @"type":user.userTypeString,
                               @"managers":user.managers,
                               @"company":user.companyKey,
                               @"timesheet":timesheetKey,
                               @"projects":user.projects};
    
    // Initialize the child updates dictionary with the user node
    NSMutableDictionary *childUpdates = [@{[@"/users/" stringByAppendingString:userKey]: userDict} mutableCopy];
    
    if (user.type == UserType_Employee) {
        
        // Add the employee to the employees members list
        childUpdates[[NSString stringWithFormat:@"/employees/members/%@/", userKey]] = @YES;
        
        // Add the employee to its company's employees list
        childUpdates[[NSString stringWithFormat:@"/companies/%@/employees/%@", user.companyKey, userKey]] = @YES;
        
        // Get the current number of users of employees to increase it by 1
        [[[self.databaseRef child:@"employees"] child:@"no_of_users"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            NSInteger noOfEmployees = [snapshot.value integerValue];
            NSNumber *increasedNoOfEmployees = [NSNumber numberWithInteger:noOfEmployees+1];
            childUpdates[@"/employees/no_of_users"] = increasedNoOfEmployees;
            
            // Atomically update all child values
            [self.databaseRef updateChildValues:childUpdates
                            withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                                if (error) {
                                    [self presentValidationErrorAlertWithTitle:@"Error"
                                                                       message:error.localizedDescription];
                                    NSLog(@"%@", error.localizedDescription);
                                } else {
                                    [self dismissController];
                                }
                            }];
            
        } withCancelBlock:^(NSError * _Nonnull error) {
            [self presentValidationErrorAlertWithTitle:@"Error"
                                               message:error.localizedDescription];
            NSLog(@"%@", error.localizedDescription);
        }];
    } else if (user.type == UserType_Manager) {
        
        // Add the manager to the managers members list
        childUpdates[[NSString stringWithFormat:@"/managers/members/%@/", userKey]] = @YES;
        
        // Get the current number of users of managers to increase it by 1
        [[[self.databaseRef child:@"managers"] child:@"no_of_users"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            NSInteger noOfManagers = [snapshot.value integerValue];
            NSNumber *increasedNoOfManagers = [NSNumber numberWithInteger:noOfManagers+1];
            childUpdates[@"/managers/no_of_users"] = increasedNoOfManagers;
            
            // Atomically update all child values
            [self.databaseRef updateChildValues:childUpdates
                            withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                                if (error) {
                                    [self presentValidationErrorAlertWithTitle:@"Error"
                                                                       message:error.localizedDescription];
                                    NSLog(@"%@", error.localizedDescription);
                                } else {
                                    [self dismissController];
                                }
                            }];
            
        } withCancelBlock:^(NSError * _Nonnull error) {
            [self presentValidationErrorAlertWithTitle:@"Error"
                                               message:error.localizedDescription];
            NSLog(@"%@", error.localizedDescription);
        }];
    } else if (user.type == UserType_Admin) {
        
        // Add the admin to the admins members list
        childUpdates[[NSString stringWithFormat:@"/admins/members/%@/", userKey]] = @YES;
        
        // Get the current number of users of admins to increase it by 1
        [[[self.databaseRef child:@"admins"] child:@"no_of_users"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            NSInteger noOfAdmins = [snapshot.value integerValue];
            NSNumber *increasedNoOfAdmins = [NSNumber numberWithInteger:noOfAdmins+1];
            childUpdates[@"/admins/no_of_users"] = increasedNoOfAdmins;
            
            // Atomically update all child values
            [self.databaseRef updateChildValues:childUpdates
                            withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                                if (error) {
                                    [self presentValidationErrorAlertWithTitle:@"Error"
                                                                       message:error.localizedDescription];
                                    NSLog(@"%@", error.localizedDescription);
                                } else {
                                    [self dismissController];
                                }
                            }];
            
        } withCancelBlock:^(NSError * _Nonnull error) {
            [self presentValidationErrorAlertWithTitle:@"Error"
                                               message:error.localizedDescription];
            NSLog(@"%@", error.localizedDescription);
        }];
    }
    
}

- (IBAction)tappedCancelButton:(id)sender
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper Methods

- (BOOL)validInput
{
    User *user = self.user;
    
    if (![user.email vol_isValidEmail]) {
        [self presentValidationErrorAlertWithTitle:@"Invalid Email"
                                           message:@"Please, verify the email format and try again."];
        return NO;
    } else if (![user.password vol_isValidPassword]) {
        [self presentValidationErrorAlertWithTitle:@"Invalid Password"
                                           message:@"Please, enter a password with at least 6 characters, one numeric digit and a letter"];
        return NO;
    } else if ([user.firstName vol_isStringEmpty] || [user.lastName vol_isStringEmpty]) {
        [self presentValidationErrorAlertWithTitle:@"No Name"
                                           message:@"A user has no name but this is not Game of Thrones. Enter one please."];
        return NO;
    } else if (user.type == UserType_Employee && [user.managers count] == 0) {
        [self presentValidationErrorAlertWithTitle:@"Manager Missing"
                                           message:@"Please, select a manager for this employee."];
        return NO;
    } else if (user.type != UserType_Admin && [user.companyKey vol_isStringEmpty]) {
        [self presentValidationErrorAlertWithTitle:@"Company Missing"
                                           message:@"Please, enter a company name for this user."];
        return NO;
    }
    
    return YES;
}

- (void)presentValidationErrorAlertWithTitle:(NSString *)errorTitle
                                     message:(NSString *)errorMessage {
    NSLog(@"Presenting Login Error Alert with message:\n%@", errorMessage);
    
    UIAlertController *alert;
    alert = [UIAlertController alertControllerWithTitle:errorTitle
                                                message:errorMessage
                                         preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction;
    defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                             style:UIAlertActionStyleDefault
                                           handler:nil];
    
    [alert addAction:defaultAction];
    
    __weak UserDetailTableViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf != nil)
            [weakSelf presentViewController:alert animated:YES completion:nil];
    });
}

- (void)dismissController {
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:^{
        UsersTableViewController *usersVC = (UsersTableViewController *)self.presentingViewController;
        if ([usersVC respondsToSelector:@selector(resetController)]) {
            [usersVC resetController];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    User *user = self.user;
    
    if (user.type == UserType_Manager) {
        return 1;
    } else if (user.type == UserType_Employee) {
        return 2;
    } else if (user.type == UserType_Admin) {
        return 1;
    }
    
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    
    switch (section) {
        case 0:
            sectionName = @"Personal Info";
            break;
            
        case 1:
            sectionName = @"Projects";
            break;
            
        default:
            break;
    }
    
    return sectionName;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    User *user = self.user;
    
    if (section ==  0) {
        if (user.type == UserType_Manager) {
            return 5;
        } else if (user.type == UserType_Employee) {
            return 6;
        } else if (user.type == UserType_Admin) {
            return 4;
        } else {
            return 0;
        }
    } else {
        return [self.projects count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *reuseIdentifier = [[NSString alloc] init];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == 0) {
        if (row == InfoField_FirstName) {
            reuseIdentifier = kFirstNameCell;
        } else if (row == InfoField_LastName) {
            reuseIdentifier = kLastNameCell;
        } else if (row == InfoField_Email) {
            reuseIdentifier = kEmailCell;
        } else if (row == InfoField_Password) {
            reuseIdentifier = kPasswordCell;
        } else if (row == InfoField_Company) {
            reuseIdentifier = kCompanyCell;
        } else if (row == InfoField_Manager) {
            reuseIdentifier = kManagerCell;
        }
    }
    
    User *user = self.user;
    
    UserDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (section == 0) {
        if (row == InfoField_FirstName) {
            cell.firstNameTextField.text = user.firstName;
        } else if (row == InfoField_LastName) {
            cell.lastNameTextField.text = user.lastName;
        } else if (row == InfoField_Email) {
            cell.emailTextField.text = user.email;
        } else if (row == InfoField_Company) {
            cell.companyTextField.text = user.companyKey;
        } else if (row == InfoField_Manager) {
            NSArray *managers = [user.managers allKeys];
            if ([managers count] > 0) {
                NSString *manager = managers[0];
                cell.managerTextField.text = manager;
            }
        }
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
    User *user = self.user;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)[[textField superview] superview]];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == 0) {
        if (row == InfoField_FirstName) {
            user.firstName = textField.text;
        } else if (row == InfoField_LastName) {
            user.lastName = textField.text;
        } else if (row == InfoField_Email) {
            user.email = textField.text;
        } else if (row == InfoField_Password) {
            user.password = textField.text;
        } else if (row == InfoField_Company) {
            user.companyKey = textField.text;
        } else if (row == InfoField_Manager) {
            [user.managers removeAllObjects];
            user.managers[textField.text] = [NSNumber numberWithBool:YES];
        }
    }
}

@end
