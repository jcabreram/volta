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
#import "AppState.h"
#import "MBProgressHUD.h"

typedef NS_ENUM (NSInteger, Field) {
    Field_Name,
    Field_TotalDuration,
    Field_Organization,
    Field_Company
};

@interface ProjectDetailTableViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;

@property (nonatomic, assign) FIRDatabaseHandle availableCompaniesHandle;
@property (nonatomic, strong) NSMutableDictionary *availableCompanies;

@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation ProjectDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Project *project = self.project;
    if (!project) {
        project = [[Project alloc] init];
    }
    
    self.availableCompanies = [[NSMutableDictionary alloc] init];
    
    if ([project.key vol_isStringEmpty]) {
        self.navigationItem.title = @"Add project";
    } else {
        self.navigationItem.title = project.name;
    }
    
    UserType currentUserType = [AppState sharedInstance].type;
    
    if (currentUserType != UserType_Manager) {
        [self.doneButton setEnabled:NO];
        [self.doneButton setTintColor:[UIColor clearColor]];
    }
    
    [self configureDatabase];
}

- (void)configureDatabase {
    self.databaseRef = [[FIRDatabase database] reference];
    
    self.availableCompaniesHandle = [self handleForObservingKeyAndNameOfChild:@"companies"];
    
    NSString *userID = [AppState sharedInstance].userID;
    UserType currentUserType = [AppState sharedInstance].type;
    
    if (currentUserType == UserType_Manager) {
        self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        
        [[[[self.databaseRef child:@"users"] child:userID] child:@"company"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            if (snapshot) {
                if ([snapshot.value isKindOfClass:[NSString class]]) {
                    self.project.companyKey = snapshot.value;
                    [self.hud hideAnimated:YES];
                }
            }
        }];
    }
}

- (FIRDatabaseHandle)handleForObservingKeyAndNameOfChild:(NSString *)child
{
    return [[self.databaseRef child:child] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSDictionary<NSString *, NSString *> *childDict = snapshot.value;
        id expectedNameString = childDict[@"name"];
        id expectedKeyString = snapshot.key;
        if (expectedNameString != nil && [expectedNameString isKindOfClass:[NSString class]] && [expectedKeyString isKindOfClass:[NSString class]]) {
            self.availableCompanies[(NSString *)expectedKeyString] = expectedNameString;
            [self.tableView reloadData];
        }
    }];
}

- (void)dealloc {
    [[self.databaseRef child:@"companies"] removeObserverWithHandle:self.availableCompaniesHandle];
}

- (IBAction)tappedDoneButton:(id)sender
{
    [self.view endEditing:YES];
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    if ([self validInput]) {
        [self updateProjectInDatabase];
    } else {
        [self.hud hideAnimated:YES];
    }
}

- (void)updateProjectInDatabase {
    NSString *userID = [AppState sharedInstance].userID;
    
    Project *project = self.project;
    
    NSString *projectKey;
    
    if ([project.key vol_isStringEmpty]) {
        projectKey = [[self.databaseRef child:@"projects"] childByAutoId].key;
    } else {
        projectKey = project.key;
    }
    
    NSDictionary *projectDict = @{@"name":project.name,
                                  @"organization":project.organization,
                                  @"company":project.companyKey,
                                  @"total_duration":@(project.totalDuration),
                                  @"created_by":userID};
    
    // Initialize the child updates dictionary with the user node
    NSMutableDictionary *childUpdates = [@{[@"/projects/" stringByAppendingString:projectKey]: projectDict} mutableCopy];
    
    // Atomically update child
    [self.databaseRef updateChildValues:childUpdates
                    withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                        [self.hud hideAnimated:YES];
                        
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
    [self dismissController];
}

#pragma mark - Helper Methods

- (BOOL)validInput
{
    Project *project = self.project;
    
    if ([project.name vol_isStringEmpty]) {
        [self presentValidationErrorAlertWithTitle:@"Name Missing"
                                           message:@"Please, enter a name for the project."];
        return NO;
    }
    
    return YES;
}

- (NSString *)textEnteredInTextField:(Field)textField
{
    ProjectDetailCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:textField inSection:0]];
    
    if (textField == Field_Name) {
        return cell.nameField.text;
    } else if (textField == Field_TotalDuration) {
        return cell.totalDurationField.text;
    } else if (textField == Field_Organization) {
        return cell.organizationField.text;
    }
    
    return @"";
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
    [self.delegate resetPresentingController];
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"* required field";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    UserType currentUserType = [AppState sharedInstance].type;
    
    if (currentUserType != UserType_Admin) {
        return 3;
    } else {
        return 4;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *reuseIdentifier;
    
    NSInteger row = indexPath.row;
    
    if (row == Field_Name) {
        reuseIdentifier = kProjectNameCell;
    } else if (row == Field_TotalDuration) {
        reuseIdentifier = kProjectTotalDurationCell;
    } else if (row == Field_Organization) {
        reuseIdentifier = kProjectOrganizationCell;
    } else if (row == Field_Company) {
        reuseIdentifier = kProjectCompanyCell;
    } else {
        reuseIdentifier = @"";
    }
    
    Project *project = self.project;
    
    ProjectDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (row == Field_Name) {
        cell.nameField.text = project.name;
    } else if (row == Field_TotalDuration) {
        if (project.totalDuration > 0) {
            cell.totalDurationField.text = [@(project.totalDuration) stringValue];
        }
    } else if (row == Field_Organization) {
        cell.organizationField.text = project.organization;
    } else if (row == Field_Company) {
        UITextField *companyField = cell.companyField;
        
        if ([companyField.text vol_isStringEmpty]) {
            companyField.text = self.availableCompanies[project.companyKey];
        }
    }
    
    // If the user is not a manager, disable the fields
    UserType currentUserType = [AppState sharedInstance].type;
    if (currentUserType != UserType_Manager) {
        cell.nameField.enabled = NO;
        cell.totalDurationField.enabled = NO;
        cell.organizationField.enabled = NO;
        cell.companyField.enabled = NO;
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
    } else if (row == Field_TotalDuration) {
        project.totalDuration = [textField.text integerValue];
    } else if (row == Field_Organization) {
        project.organization = textField.text;
    } else if (row == Field_Company) {
        project.companyKey = textField.text;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.tag == Field_TotalDuration) {
        // Allow backspace
        if (!string.length) {
            return YES;
        }
        
        if ([string rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet].invertedSet].location != NSNotFound) {
            return NO;
        }
        
        NSString *proposedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
        
        if (proposedText.length > 5) {
            return NO;
        }
        
        return YES;
    } else {
        return YES;
    }
}

@end
