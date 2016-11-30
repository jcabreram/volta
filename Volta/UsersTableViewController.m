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

@import Firebase;

@interface UsersTableViewController ()

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;
@property (nonatomic, assign) FIRDatabaseHandle referenceHandle;
@property (nonatomic, strong) NSMutableArray<FIRDataSnapshot *> *users;

@end

@implementation UsersTableViewController

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.users = [[NSMutableArray alloc] init];
    
    [self configureDatabase];
}

#pragma mark -

- (void)configureDatabase {
    self.databaseRef = [[FIRDatabase database] reference];
    self.referenceHandle = [[_databaseRef child:@"users"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        [self.users addObject:snapshot];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.users.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//    if ([segue.identifier isEqualToString:SeguesAddManager]) {
//        UINavigationController *navigationController = segue.destinationViewController;
//        UserDetailTableViewController *userDetailController = navigationController.childViewControllers[0];
//        
//        
//    }
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
    
    FIRDataSnapshot *userSnapshot = _users[indexPath.row];
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

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
