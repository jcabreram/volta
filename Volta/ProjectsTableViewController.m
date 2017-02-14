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
#import "UIImage+VOLImage.h"

@interface ProjectsTableViewController ()

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;
@property (nonatomic, assign) FIRDatabaseHandle projectsHandle;
@property (nonatomic, assign) FIRDatabaseHandle userProjectsHandle;

@property (nonatomic, strong) NSMutableArray<FIRDataSnapshot *> *projects;
@property (nonatomic, strong) Project *selectedProject;

@end

@implementation ProjectsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Change the navigation bar color to gradient
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageLayerForGradientBackgroundWithBounds:self.navigationController.navigationBar.bounds] forBarMetrics:UIBarMetricsDefault];
    
    // If the user is an employee or admin, don't show the create project toolbar
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
    
    // Load the users data back from the database
    [[self.databaseRef child:@"projects"] removeObserverWithHandle:self.projectsHandle];
    [self configureDatabase];
    
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *navigationController = segue.destinationViewController;
    
    // Change the navigation bar color to gradient
    [navigationController.navigationBar setBackgroundImage:[UIImage imageLayerForGradientBackgroundWithBounds:self.navigationController.navigationBar.bounds] forBarMetrics:UIBarMetricsDefault];
    
    ProjectDetailTableViewController *projectDetailController = navigationController.childViewControllers[0];
    
    projectDetailController.delegate = self;
    
    if (!self.selectedProject) {
        self.selectedProject = [[Project alloc] init];
    }
    
    if ([segue.identifier isEqualToString:SeguesShowProjectDetail]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        
        FIRDataSnapshot *projectSnapshot = self.projects[indexPath.row];
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

- (void)sortProjectsArray
{
    NSSortDescriptor *projectNameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"value.name" ascending:YES selector:@selector(localizedStandardCompare:)];
    self.projects = [[self.projects sortedArrayUsingDescriptors:@[projectNameSortDescriptor]] mutableCopy];
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
                    [self.projects addObject:snapshot];
                    [self sortProjectsArray];
                    [self.tableView reloadData];
                }
            }];
            
            
        }];
    } else if (currentUserType == UserType_Manager) {
        self.projectsHandle = [[_databaseRef child:@"projects"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            if (snapshot.exists) {
                if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *project = snapshot.value;
                    if ([project[@"created_by"] isEqualToString:loggedUserKey]) {
                        [self.projects addObject:snapshot];
                        [self sortProjectsArray];
                        [self.tableView reloadData];
                    }
                }
            }
        }];
    } else {
        self.projectsHandle = [[_databaseRef child:@"projects"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            if (snapshot.exists) {
                [self.projects addObject:snapshot];
                [self sortProjectsArray];
                [self.tableView reloadData];
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
    UserType currentUserType = [AppState sharedInstance].type;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProjectCell" forIndexPath:indexPath];
    
    FIRDataSnapshot *project = self.projects[indexPath.row];
    NSDictionary *projectDict = project.value;
    
    NSString *projectName = projectDict[@"name"];
    cell.textLabel.text = projectName;
    
    NSNumber *totalDuration = projectDict[@"total_duration"];
    NSNumber *currentDuration = projectDict[@"current_duration"];
    
    if (!currentDuration) {
        currentDuration = @(0);
    }
    
    if (!totalDuration) {
        totalDuration = @(0);
    }
    
    UIColor *durationColor;
    if ([currentDuration doubleValue] > [totalDuration doubleValue]) {
        durationColor = [UIColor redColor];
    } else {
        durationColor = [UIColor blackColor];
    }
    
    NSString *durationString = [NSString stringWithFormat:@"%@ / %@ hrs", currentDuration, totalDuration];
    NSAttributedString *attributedDuration = [[NSAttributedString alloc] initWithString:durationString
                                                                             attributes:@{
                                                                                          NSForegroundColorAttributeName : durationColor
                                                                                          }];
    
    NSString *companyKey = projectDict[@"company"];
    
    if (currentUserType == UserType_Admin) {
        [[[[self.databaseRef child:@"companies"] child:companyKey] child:@"name"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            if (snapshot.exists) {
                if ([snapshot.value isKindOfClass:[NSString class]]) {
                    NSString *company = snapshot.value;
                    NSMutableAttributedString *attributedDetail = [[NSMutableAttributedString alloc] initWithString:company];
                    [attributedDetail beginEditing];
                    NSAttributedString *attributedSeparator = [[NSAttributedString alloc] initWithString:@" - "];
                    [attributedDetail appendAttributedString:attributedSeparator];
                    [attributedDetail appendAttributedString:attributedDuration];
                    [attributedDetail endEditing];
                    cell.detailTextLabel.attributedText = attributedDetail;
                }
            }
        }];
    } else {
        cell.detailTextLabel.attributedText = attributedDuration;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self performSegueWithIdentifier:SeguesShowProjectDetail sender:cell];
}

@end
