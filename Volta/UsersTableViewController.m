//
//  UsersTableViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/29/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "UsersTableViewController.h"
#import "UserDetailTableViewController.h"
#import "Constants.h"
#import "User.h"

@import Firebase;

@interface UsersTableViewController ()

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;
@property (nonatomic, assign) FIRDatabaseHandle referenceHandle;
@property (nonatomic, strong) NSMutableArray<FIRDataSnapshot *> *users;
@property (nonatomic, strong) User *selectedUser;

@end

@implementation UsersTableViewController

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.users = [[NSMutableArray alloc] init];
    
    [self configureDatabase];
}

- (void)resetPresentingController {
    self.selectedUser = [[User alloc] init];
    
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    if (indexPath) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *navigationController = segue.destinationViewController;
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
        FIRDataSnapshot *userSnapshot = _users[indexPath.row];
        NSDictionary *user = userSnapshot.value;
        NSString *userKey = userSnapshot.key;
        
        self.selectedUser = [[User alloc] initWithKey:userKey
                                            firstName:user[@"first_name"]
                                             lastName:user[@"last_name"]
                                                email:user[@"email"]
                                             password:user[@"first_name"]
                                            createdAt:[NSDate dateWithTimeIntervalSince1970:[user[@"date"] doubleValue]]
                                                 type:[User userTypeFromString:user[@"type"]]
                                            employees:user[@"employees"]
                                             managers:user[@"managers"]
                                           companyKey:user[@"company"]
                                            timesheet:user[@"timesheet"]
                                             projects:user[@"projects"]];
    }
    
    userDetailController.user = self.selectedUser;
}

#pragma mark - Database

- (void)configureDatabase {
    self.databaseRef = [[FIRDatabase database] reference];
    self.referenceHandle = [[_databaseRef child:@"users"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        [self.users addObject:snapshot];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.users.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (void)dealloc {
    [[self.databaseRef child:@"users"] removeObserverWithHandle:self.referenceHandle];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
    
    FIRDataSnapshot *userSnapshot = self.users[indexPath.row];
    NSDictionary<NSString *, NSString *> *user = userSnapshot.value;
    
    NSString *firstName = user[@"first_name"];
    NSString *lastName = user[@"last_name"];
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    cell.textLabel.text = fullName;
    
    NSString *rawType = user[@"type"];
    cell.detailTextLabel.text = [rawType capitalizedString];
    
    return cell;
}

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

@end
