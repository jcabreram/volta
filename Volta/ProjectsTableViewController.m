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

@interface ProjectsTableViewController ()

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;
@property (nonatomic, assign) FIRDatabaseHandle referenceHandle;
@property (nonatomic, strong) NSMutableArray<FIRDataSnapshot *> *projects;
@property (nonatomic, strong) Project *selectedProject;

@end

@implementation ProjectsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.projects = [[NSMutableArray alloc] init];
    
    [self configureDatabase];
}

- (void)resetPresentingController {
    self.selectedProject = [[Project alloc] init];
    
    // Clear the projects data and reload the table to empty it
    [self.projects removeAllObjects];
    [self.tableView reloadData];
    
    // Load the project data back from the database
    [[self.databaseRef child:@"projects"] removeObserverWithHandle:self.referenceHandle];
    [self configureDatabase];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *navigationController = segue.destinationViewController;
    ProjectDetailTableViewController *projectDetailController = navigationController.childViewControllers[0];
    
    projectDetailController.delegate = self;
    
    if (!self.selectedProject) {
        self.selectedProject = [[Project alloc] init];
    }
    
    if ([segue.identifier isEqualToString:SeguesShowProjectDetail]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        FIRDataSnapshot *projectSnapshot = _projects[indexPath.row];
        NSDictionary *project = projectSnapshot.value;
        NSString *projectKey = projectSnapshot.key;
        
        self.selectedProject = [[Project alloc] initWithKey:projectKey
                                                       name:project[@"name"]
                                               organization:project[@"organization"]
                                                 companyKey:project[@"company"]
                                              totalDuration:[project[@"total_duration"] integerValue]];
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

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self performSegueWithIdentifier:SeguesShowProjectDetail sender:cell];
}

@end
