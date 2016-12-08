//
//  ProjectDetailTableViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 12/6/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "ProjectsTableViewController.h"
#import "ProjectDetailTableViewController.h"
#import "ProjectDetailCell.h"
#import "Project.h"
#import "Constants.h"
#import "NSString+VOLValidation.h"

@import Firebase;

typedef NS_ENUM (NSInteger, Field) {
    Field_Name,
    Field_DefaultDuration,
    Field_Organization,
    Field_Company
};

@interface ProjectDetailTableViewController ()

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;

@end

@implementation ProjectDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Project *project = self.project;
    
    if (!project) {
        project = [[Project alloc] init];
    }
    
    if ([project.key vol_isStringEmpty]) {
        self.navigationItem.title = @"Add project";
    } else {
        self.navigationItem.title = project.name;
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
        [self updateUserInDatabase];
    }
}

- (void)updateUserInDatabase {
    Project *project = self.project;
    
    NSString *projectKey;
    
    if ([project.key vol_isStringEmpty]) {
        projectKey = [[self.databaseRef child:@"users"] childByAutoId].key;
    } else {
        projectKey = project.key;
    }
    
    NSDictionary *projectDict = @{@"name":project.name,
                                  @"organization":project.organization,
                                  @"company":project.companyKey,
                                  @"default_duration":[NSNumber numberWithInteger:project.defaultDuration]};
    
    // Initialize the child updates dictionary with the user node
    NSMutableDictionary *childUpdates = [@{[@"/projects/" stringByAppendingString:projectKey]: projectDict} mutableCopy];
    
    // Atomically update child
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
}

- (IBAction)tappedCancelButton:(id)sender
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper Methods

- (BOOL)validInput
{
    Project *project = self.project;
    
    if ([project.name vol_isStringEmpty]) {
        [self presentValidationErrorAlertWithTitle:@"Name Missing"
                                           message:@"Please, enter a name for the project."];
        return NO;
    } else if ([project.companyKey vol_isStringEmpty]) {
        [self presentValidationErrorAlertWithTitle:@"Company Missing"
                                           message:@"Please, enter the company for this project"];
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
    
    __weak ProjectDetailTableViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf != nil)
            [weakSelf presentViewController:alert animated:YES completion:nil];
    });
}

- (void)dismissController {
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:^{
        ProjectsTableViewController *projectsVC = (ProjectsTableViewController *)self.presentingViewController;
        if ([projectsVC respondsToSelector:@selector(resetController)]) {
            [projectsVC resetController];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName = @"Project Info";
    
    return sectionName;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // TODO: If the user is an employee, hide the company row
    
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *reuseIdentifier = [[NSString alloc] init];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (row == Field_Name) {
        reuseIdentifier = kProjectNameCell;
    } else if (row == Field_DefaultDuration) {
        reuseIdentifier = kProjectDefaultDurationCell;
    } else if (row == Field_Organization) {
        reuseIdentifier = kProjectOrganizationCell;
    } else if (row == Field_Company) {
        reuseIdentifier = kProjectCompanyCell;
    }
    
    Project *project = self.project;
    
    ProjectDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (row == Field_Name) {
        cell.nameField.text = project.name;
    } else if (row == Field_DefaultDuration) {
        if (project.defaultDuration > 0) {
            cell.defaultDurationField.text = [@(project.defaultDuration) stringValue];
        }
    } else if (row == Field_Organization) {
        cell.organizationField.text = project.organization;
    } else if (row == Field_Company) {
        cell.companyField.text = project.companyKey;
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
    Project *project = self.project;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)[[textField superview] superview]];
    NSInteger row = indexPath.row;

    if (row == Field_Name) {
        project.name = textField.text;
    } else if (row == Field_DefaultDuration) {
        project.defaultDuration = [textField.text integerValue];
    } else if (row == Field_Organization) {
        project.organization = textField.text;
    } else if (row == Field_Company) {
        project.companyKey = textField.text;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.tag == 2) {
        // Allow backspace
        if (!string.length) {
            return YES;
        }
        
        if ([string intValue]) {
            return YES;
        }
        
        return NO;
    } else {
        return YES;
    }
}

@end
