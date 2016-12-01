//
//  UserDetailTableViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/29/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "UserDetailTableViewController.h"
#import "User.h"
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
    
    switch (self.mode) {
        case ControllerMode_Admin:
            self.navigationItem.title = @"Add admin";
            break;
    
        case ControllerMode_Manager:
            self.navigationItem.title = @"Add manager";
            break;
            
        case ControllerMode_Employee:
            self.navigationItem.title = @"Add employee";
            break;
            
        default:
            break;
    }
    
    self.projects = [[NSMutableArray alloc] init];
    
    if (!self.user) {
        self.user = [[User alloc] init];
    }
    
    [self configureDatabase];
}

- (void)configureDatabase {
    _databaseRef = [[FIRDatabase database] reference];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)tappedDoneButton:(id)sender {
    
    [self.view endEditing:YES];
    
    User *user = self.user;
    
    NSString *creatorID = [FIRAuth auth].currentUser.uid;
    
    NSString *timesheetKey = [[self.databaseRef child:@"timesheets"] childByAutoId].key;
    NSString *userKey = [[self.databaseRef child:@"users"] childByAutoId].key;
    
    NSDictionary *userDict = @{@"email":user.email,
                               @"first_name":user.firstName,
                               @"last_name":user.lastName,
                               @"created_at":[NSNumber numberWithDouble:[user.createdAt timeIntervalSince1970]],
                               @"created_by":creatorID,
                               @"type":user.userTypeString,
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
                                    NSLog(@"%@", error.localizedDescription);
                                } else {
                                    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
                                }
                            }];
            
        } withCancelBlock:^(NSError * _Nonnull error) {
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
                                    NSLog(@"%@", error.localizedDescription);
                                } else {
                                    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
                                }
                            }];
            
        } withCancelBlock:^(NSError * _Nonnull error) {
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
                                    NSLog(@"%@", error.localizedDescription);
                                } else {
                                    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
                                }
                            }];
            
        } withCancelBlock:^(NSError * _Nonnull error) {
            NSLog(@"%@", error.localizedDescription);
        }];
    }
}

- (IBAction)tappedCancelButton:(id)sender {
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.mode == ControllerMode_Manager) {
        return 1;
    } else if (self.mode == ControllerMode_Employee) {
        return 2;
    } else if (self.mode == ControllerMode_Admin) {
        return 1;
    }
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section ==  0) {
        if (self.mode == ControllerMode_Manager) {
            return 5;
        } else if (self.mode == ControllerMode_Employee) {
            return 6;
        } else if (self.mode == ControllerMode_Admin) {
            return 4;
        } else {
            return 0;
        }
    } else {
        return [self.projects count];
    }
}

/*
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
 
 // Configure the cell...
 
 return cell;
 }
 */

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

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
