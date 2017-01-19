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
#import "AppState.h"

@interface ProjectsTableViewController ()

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;
@property (nonatomic, assign) FIRDatabaseHandle projectsHandle;
@property (nonatomic, assign) FIRDatabaseHandle userProjectsHandle;

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *projects;
@property (nonatomic, strong) Project *selectedProject;

@end

@implementation ProjectsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // If the user is an employee, don't show him the create project toolbar
    UserType currentUserType = [AppState sharedInstance].type;
    if (currentUserType == UserType_Employee || currentUserType == UserType_Admin) {
        self.navigationController.toolbarHidden = YES;
    }
    
    self.projects = [[NSMutableArray alloc] init];
    
    [self configureDatabase];
}

- (void)resetPresentingController {
    self.selectedProject = [[Project alloc] init];
    
    // Clear the projects data and reload the table to empty it
    [self.projects removeAllObjects];
    [self.tableView reloadData];
    
    // Load the project data back from the database
    [self removeObservers];
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
        NSDictionary *project = _projects[indexPath.row];
        NSDictionary *projectData = [[project allValues] firstObject];
        NSString *projectKey = [[project allKeys] firstObject];
        
        self.selectedProject = [[Project alloc] initWithKey:projectKey
                                                       name:projectData[@"name"]
                                               organization:projectData[@"organization"]
                                                 companyKey:projectData[@"company"]
                                              totalDuration:[projectData[@"total_duration"] integerValue]];
    }
    
    projectDetailController.project = self.selectedProject;
}

#pragma mark - Database

- (void)configureDatabase {
    self.databaseRef = [[FIRDatabase database] reference];
    UserType currentUserType = [AppState sharedInstance].type;
    NSString *loggedUserKey = [AppState sharedInstance].userID;
    
    if (currentUserType == UserType_Employee) {
        self.userProjectsHandle = [[[[self.databaseRef child:@"users"] child:loggedUserKey] child:@"projects"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            NSString *userProjectKey = snapshot.key;
            
            [[[self.databaseRef child:@"projects"] child:userProjectKey] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                if (snapshot.exists) {
                    [self.projects addObject:@{snapshot.key : snapshot.value}];
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.projects.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }];
            
            
        }];
    } else if (currentUserType == UserType_Manager) {
        self.projectsHandle = [[_databaseRef child:@"projects"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            if (snapshot.exists) {
                if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *project = snapshot.value;
                    if ([project[@"created_by"] isEqualToString:loggedUserKey]) {
                        [self.projects addObject:@{snapshot.key : snapshot.value}];
                        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.projects.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }
            }
        }];
    } else {
        self.projectsHandle = [[_databaseRef child:@"projects"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            if (snapshot.exists) {
                [self.projects addObject:@{snapshot.key : snapshot.value}];
                [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.projects.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }];
    }
}

- (void)dealloc {
    [self removeObservers];
}

- (void)removeObservers
{
    NSString *loggedUserKey = [AppState sharedInstance].userID;
    
    [[self.databaseRef child:@"projects"] removeObserverWithHandle:self.projectsHandle];
    [[[[self.databaseRef child:@"users"] child:loggedUserKey] child:@"projects"] removeObserverWithHandle:self.userProjectsHandle];
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
    
    NSDictionary *project = self.projects[indexPath.row];
    NSDictionary *projectData = [[project allValues] firstObject];
    
    NSString *projectName = projectData[@"name"];
    cell.textLabel.text = projectName;
    
    NSString *companyKey = projectData[@"company"];
    
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
