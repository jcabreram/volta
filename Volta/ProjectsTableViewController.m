//
//  ProjectsTableViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/22/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "ProjectsTableViewController.h"
#import "ProjectDetailTableViewController.h"
#import "Constants.h"
#import "Project.h"

@import Firebase;

@interface ProjectsTableViewController ()

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;
@property (nonatomic, assign) FIRDatabaseHandle referenceHandle;
@property (nonatomic, strong) NSMutableArray<FIRDataSnapshot *> *projects;
@property (nonatomic, strong) Project *selectedProject;

@end

@implementation ProjectsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.projects = [[NSMutableArray alloc] init];
    
    [self configureDatabase];
}

- (void)resetController {
    self.selectedProject = [[Project alloc] init];
    
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    if (indexPath) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *navigationController = segue.destinationViewController;
    ProjectDetailTableViewController *projectDetailController = navigationController.childViewControllers[0];
    
    if (!self.selectedProject) {
        self.selectedProject = [[Project alloc] init];
    }
    
    if ([segue.identifier isEqualToString:SeguesAddProject]) {
        
    } else if ([segue.identifier isEqualToString:SeguesShowProjectDetail]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        FIRDataSnapshot *projectSnapshot = _projects[indexPath.row];
        NSDictionary *project = projectSnapshot.value;
        NSString *projectKey = projectSnapshot.key;
        
        self.selectedProject = [[Project alloc] initWithKey:projectKey
                                                       name:project[@"name"]
                                               organization:project[@"organization"]
                                                 companyKey:project[@"company"]
                                            defaultDuration:[project[@"default_duration"] integerValue]];
    }
    
    projectDetailController.project = self.selectedProject;
}

#pragma mark - Database

- (void)configureDatabase {
    self.databaseRef = [[FIRDatabase database] reference];
    self.referenceHandle = [[_databaseRef child:@"projects"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        [self.projects addObject:snapshot];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.projects.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (void)dealloc {
    [[self.databaseRef child:@"projects"] removeObserverWithHandle:self.referenceHandle];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.projects count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProjectCell" forIndexPath:indexPath];
    
    FIRDataSnapshot *projectSnapshot = self.projects[indexPath.row];
    NSDictionary<NSString *, NSString *> *project = projectSnapshot.value;
    
    NSString *projectName = project[@"name"];
    cell.textLabel.text = projectName;
    
    NSString *companyKey = project[@"company"];
    
    [[[[self.databaseRef child:@"companies"] child:companyKey] child:@"name"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        if ([snapshot.value isKindOfClass:[NSString class]]) {
            cell.detailTextLabel.text = snapshot.value;
        }
        
    }];
    
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
