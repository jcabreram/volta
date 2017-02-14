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
#import "MBProgressHUD.h"

typedef NS_ENUM (NSInteger, FieldTag) {
    FieldTag_FirstName,
    FieldTag_LastName,
    FieldTag_Email,
    FieldTag_Password,
    FieldTag_Company,
    FieldTag_Manager,
    FieldTag_RequiresPhoto,
    FieldTag_Project
};

typedef NS_ENUM (NSInteger, SectionNumber) {
    SectionNumber_One,
    SectionNumber_Two
};

@interface UserDetailTableViewController ()

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;

@property (nonatomic, assign) FIRDatabaseHandle availableProjectsHandle;
@property (nonatomic, assign) FIRDatabaseHandle availableCompaniesHandle;
@property (nonatomic, assign) FIRDatabaseHandle availableManagersHandle;

@property (nonatomic, strong) NSMutableDictionary *availableProjects;
@property (nonatomic, strong) NSMutableDictionary *availableCompanies;
@property (nonatomic, strong) NSMutableDictionary *availableManagers;

@property (nonatomic, strong) NSArray *userProjectKeys;

@property (nonatomic, assign) NSInteger numberOfProjectsShown;

@property (nonatomic, assign) BOOL newUser;

@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation UserDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    User *user = self.user;
    
    if (!user) {
        user = [[User alloc] init];
    }
    
    self.availableProjects = [[NSMutableDictionary alloc] init];
    self.availableCompanies = [[NSMutableDictionary alloc] init];
    self.availableManagers = [[NSMutableDictionary alloc] init];
    
    self.userProjectKeys = [user.projects allKeys];
    
    self.numberOfProjectsShown = [user.projects count] + 1;
    
    if ([user.key vol_isStringEmpty]) {
        self.newUser = YES;
    } else {
        self.newUser = NO;
    }
    
    if (self.newUser) {
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
    UserType currentUserType = [AppState sharedInstance].type;
    NSString *loggedUserKey = [AppState sharedInstance].userID;
    
    self.availableProjectsHandle = [[self.databaseRef child:@"projects"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *project = snapshot.value;
            
            if (currentUserType != UserType_Manager ||  [project[@"created_by"] isEqualToString:loggedUserKey]) {
                id projectName = project[@"name"];
                id projectKey = snapshot.key;
                if ([projectName isKindOfClass:[NSString class]] && [projectKey isKindOfClass:[NSString class]]) {
                    self.availableProjects[(NSString *)projectKey] = projectName;
                }
            }
        }
    }];
    
    self.availableCompaniesHandle = [self handleForObservingKeyAndNameOfChild:@"companies"
                                                     usingDictionary:self.availableCompanies];
    
    self.availableManagersHandle = [[[self.databaseRef child:@"managers"] child:@"members"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        [[[[self.databaseRef child:@"users"] queryOrderedByKey] queryEqualToValue:snapshot.key] observeSingleEventOfType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            NSDictionary<NSString *, NSString *> *userDict = snapshot.value;
            NSString *fullName = [NSString stringWithFormat:@"%@ %@", userDict[@"first_name"], userDict[@"last_name"]];
            self.availableManagers[snapshot.key] = fullName;
            [self.tableView reloadData];
        }];
       
    }];
}

- (FIRDatabaseHandle)handleForObservingKeyAndNameOfChild:(NSString *)child
                                         usingDictionary:(NSMutableDictionary *)outputDict {
    return [[self.databaseRef child:child] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSDictionary<NSString *, NSString *> *childDict = snapshot.value;
        id expectedNameString = childDict[@"name"];
        id expectedKeyString = snapshot.key;
        if (expectedNameString != nil && [expectedNameString isKindOfClass:[NSString class]] && [expectedKeyString isKindOfClass:[NSString class]]) {
            outputDict[(NSString *)expectedKeyString] = expectedNameString;
        }
    }];
}

- (void)dealloc {
    [[self.databaseRef child:@"projects"] removeObserverWithHandle:self.availableProjectsHandle];
    [[self.databaseRef child:@"companies"] removeObserverWithHandle:self.availableCompaniesHandle];
    [[self.databaseRef child:@"managers"] removeObserverWithHandle:self.availableManagersHandle];
}

- (void)updateProjects
{
    User *user = self.user;
    
    [user.projects removeAllObjects];
    
    for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:1]; ++i) {
        NSString *projectName = [self textEnteredInTextField:i forSection:SectionNumber_Two];
        NSArray *projectsKeys = [self.availableProjects allKeysForObject:projectName];
        
        if ([projectsKeys count] > 0) {
            NSString *projectKey = [projectsKeys firstObject];
            user.projects[projectKey] = @(YES);
        }
    }
}

- (void)updateDatabaseWithUserUID:(NSString *)userUID {
    
    User *user = self.user;
    
    // We create the company first if it's not already on the existing list of companies on the database, then we call updateUserInDatabase when that's ready to continue with the user creation process
    
    if (user.type == UserType_Employee || user.type == UserType_Manager) {
        NSString *companyName = [self textEnteredInTextField:FieldTag_Company forSection:SectionNumber_One];
        NSArray *companyKeys = [self.availableCompanies allKeysForObject:companyName];
        
        if ([companyKeys count] > 0) {
            NSString *companyKey = [companyKeys firstObject];
            user.companyKey = companyKey;
            [self updateUserInDatabaseWithUserUID:userUID];
        } else {
            user.companyKey = [[self.databaseRef child:@"companies"] childByAutoId].key;
            
            NSDictionary *companyStructure = @{@"name":companyName};
            
            NSMutableDictionary *childUpdates = [@{[@"/companies/" stringByAppendingString:user.companyKey]: companyStructure} mutableCopy];
            
            [self.databaseRef updateChildValues:childUpdates
                            withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                                if (error) {
                                    [self presentValidationErrorAlertWithTitle:@"Error"
                                                                       message:error.localizedDescription];
                                    NSLog(@"%@", error.localizedDescription);
                                } else {
                                    [self updateUserInDatabaseWithUserUID:userUID];
                                }
                            }];
        }
    } else {
        [self updateUserInDatabaseWithUserUID:userUID];
    }
}

- (void)updateUserInDatabaseWithUserUID:(NSString *)userUID {
    User *user = self.user;
    
    NSString *creatorID = [AppState sharedInstance].userID;
    
    NSString *timesheetKey;
    
    if ([user.timesheet vol_isStringEmpty]) {
        timesheetKey = [[self.databaseRef child:@"timesheets"] childByAutoId].key;
    } else {
        timesheetKey = user.timesheet;
    }
    
    if (!user.projects) {
        user.projects = [[NSMutableDictionary alloc] init];
    }
    
    if (!user.managers) {
        user.managers = [[NSMutableDictionary alloc] init];
    }
    
    NSDictionary *userDict = @{@"email":user.email,
                               @"first_name":user.firstName,
                               @"last_name":user.lastName,
                               @"created_at":@([user.createdAt timeIntervalSince1970]),
                               @"created_by":creatorID,
                               @"type":user.userTypeString,
                               @"managers":user.managers,
                               @"company":user.companyKey,
                               @"timesheet":timesheetKey,
                               @"projects":user.projects,
                               @"requires_photo":@(user.requiresPhoto)};
    
    // Initialize the child updates dictionary with the user node
    NSMutableDictionary *childUpdates = [@{[@"/users/" stringByAppendingString:userUID]: userDict} mutableCopy];
    
    if (user.type == UserType_Employee) {
        
        // Add the employee to the employees members list
        childUpdates[[NSString stringWithFormat:@"/employees/members/%@/", userUID]] = @YES;
        
        // Add the employee to its company's employees list
        childUpdates[[NSString stringWithFormat:@"/companies/%@/employees/%@", user.companyKey, userUID]] = @YES;
        
        // Add the employee to its managers' employees list
        for (NSString *managerKey in user.managers) {
            childUpdates[[NSString stringWithFormat:@"/users/%@/employees/%@", managerKey, userUID]] = @YES;
        }
        
        // Add the employee ID and his manager's ID to the timesheet for easy notifications
        childUpdates[[NSString stringWithFormat:@"/timesheets/%@/user", timesheetKey]] = userUID;
        childUpdates[[NSString stringWithFormat:@"/timesheets/%@/manager", timesheetKey]] = [[user.managers allKeys] firstObject];
        
        // Get the current number of employees to increase it by 1
        [[[self.databaseRef child:@"employees"] child:@"no_of_users"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            NSInteger noOfEmployees = [snapshot.value integerValue];
            NSNumber *increasedNoOfEmployees = @(noOfEmployees+1);
            childUpdates[@"/employees/no_of_users"] = increasedNoOfEmployees;
            
            // Atomically update all child values
            [self.databaseRef updateChildValues:childUpdates
                            withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                                [self.hud hideAnimated:YES];
                                
                                if (error) {
                                    [self presentValidationErrorAlertWithTitle:@"Error"
                                                                       message:error.localizedDescription];
                                    NSLog(@"%@", error.localizedDescription);
                                } else {
                                    [self finishedCreatingUser];
                                }
                            }];
            
        } withCancelBlock:^(NSError * _Nonnull error) {
            [self presentValidationErrorAlertWithTitle:@"Error"
                                               message:error.localizedDescription];
            NSLog(@"%@", error.localizedDescription);
        }];
    } else if (user.type == UserType_Manager) {
        
        // Add the manager to the managers members list
        childUpdates[[NSString stringWithFormat:@"/managers/members/%@/", userUID]] = @YES;
        
        // Get the current number of users of managers to increase it by 1
        [[[self.databaseRef child:@"managers"] child:@"no_of_users"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            NSInteger noOfManagers = [snapshot.value integerValue];
            NSNumber *increasedNoOfManagers = @(noOfManagers+1);
            childUpdates[@"/managers/no_of_users"] = increasedNoOfManagers;
            
            // Atomically update all child values
            [self.databaseRef updateChildValues:childUpdates
                            withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                                [self.hud hideAnimated:YES];
                                
                                if (error) {
                                    [self presentValidationErrorAlertWithTitle:@"Error"
                                                                       message:error.localizedDescription];
                                    NSLog(@"%@", error.localizedDescription);
                                } else {
                                    [self finishedCreatingUser];
                                }
                            }];
            
        } withCancelBlock:^(NSError * _Nonnull error) {
            [self.hud hideAnimated:YES];
            [self presentValidationErrorAlertWithTitle:@"Error"
                                               message:error.localizedDescription];
            NSLog(@"%@", error.localizedDescription);
        }];
    } else if (user.type == UserType_Admin) {
        
        // Add the admin to the admins members list
        childUpdates[[NSString stringWithFormat:@"/admins/members/%@/", userUID]] = @YES;
        
        // Get the current number of users of admins to increase it by 1
        [[[self.databaseRef child:@"admins"] child:@"no_of_users"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            NSInteger noOfAdmins = [snapshot.value integerValue];
            NSNumber *increasedNoOfAdmins = @(noOfAdmins+1);
            childUpdates[@"/admins/no_of_users"] = increasedNoOfAdmins;
            
            // Atomically update all child values
            [self.databaseRef updateChildValues:childUpdates
                            withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                                [self.hud hideAnimated:YES];
                                if (error) {
                                    [self presentValidationErrorAlertWithTitle:@"Error"
                                                                       message:error.localizedDescription];
                                    NSLog(@"%@", error.localizedDescription);
                                } else {
                                    [self finishedCreatingUser];
                                }
                            }];
            
        } withCancelBlock:^(NSError * _Nonnull error) {
            [self.hud hideAnimated:YES];
            [self presentValidationErrorAlertWithTitle:@"Error"
                                               message:error.localizedDescription];
            NSLog(@"%@", error.localizedDescription);
        }];
    }
}

- (void)finishedCreatingUser
{
    if (self.newUser) {
        [self showMailComposeController];
    } else {
        [self dismissController];
    }
}

- (void)showMailComposeController
{
    User *user = self.user;
    AppState *state = [AppState sharedInstance];
    NSString *adminName = state.displayName;
    
    NSString *emailTitle = @"Welcome to Volta!";
    
    NSString *htmlFilePath = [[NSBundle mainBundle] pathForResource:@"Welcome email" ofType:@"html"];
    NSMutableString *html = [[NSString stringWithContentsOfFile:htmlFilePath encoding:NSUTF8StringEncoding error:nil] mutableCopy];
    
    if (user.type != UserType_Employee) {
        [html replaceOccurrencesOfString:@"<p>As an <strong>employee</strong> in Volta, you&#39;ll be able to enter timesheets, specify projects worked on the day and send them for approval in an easy and faster way. </p>" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [html length])];
    }
    
    if (user.type != UserType_Manager) {
        [html replaceOccurrencesOfString:@"<p>As a <strong>manager</strong> in Volta, you&#39;ll be able to inspect and approve your employees&#39; timesheets, as well as create and assign projects to them so that they can enter them on their timesheets.</p>" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [html length])];
    }
    
    if (user.type != UserType_Admin) {
        [html replaceOccurrencesOfString:@"<p>As an <strong>admin</strong> in Volta, you&#39;ll be able to create users, assign them to projects, see Ksquare employees&#39; timesheets and download their weekly report.</p>" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [html length])];
    }
    
    [html replaceOccurrencesOfString:@"%newUserName%" withString:user.firstName options:NSCaseInsensitiveSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"%email%" withString:user.email options:NSCaseInsensitiveSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"%password%" withString:user.password options:NSCaseInsensitiveSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"%adminName%" withString:adminName options:NSCaseInsensitiveSearch range:NSMakeRange(0, [html length])];
    
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    mailController.mailComposeDelegate = self;
    [mailController setSubject:emailTitle];
    [mailController setMessageBody:html isHTML:YES];
    [mailController setToRecipients:@[user.email]];
    
    [self presentViewController:mailController animated:YES completion:nil];
}

#pragma mark - IBAction Methods

- (IBAction)tappedDoneButton:(id)sender
{
    [self.view endEditing:YES];
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    
    NSString *secondaryAppString = [[[NSProcessInfo processInfo] globallyUniqueString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    if ([self validInput]) {
        
        User *user = self.user;
        
        // Before creating the user, we update the User object's projects to its respective keys
        if (user.type == UserType_Employee) {
            [self updateProjects];
        }
        
        if ([user.key vol_isStringEmpty]) {
            
            // Creating the user on another app instance so that the current user isn't logged out
            // Source: http://stackoverflow.com/questions/37517208/firebase-kicks-out-current-user/37614090#37614090
            
            NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
            FIROptions *secondaryAppOptions = [[FIROptions alloc] initWithContentsOfFile:plistPath];
            [FIRApp configureWithName:secondaryAppString options:secondaryAppOptions];
            FIRApp *secondaryApp = [FIRApp appNamed:secondaryAppString];
            FIRAuth *secondaryAppAuth = [FIRAuth authWithApp:secondaryApp];
            
            [secondaryAppAuth createUserWithEmail:user.email
                                         password:user.password
                                       completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                                           [secondaryAppAuth signOut:nil];
                                           
                                           if (error) {
                                               [self presentValidationErrorAlertWithTitle:@"Error"
                                                                                  message:error.localizedDescription];
                                               NSLog(@"%@", error.localizedDescription);
                                           } else {
                                               
                                               [self updateDatabaseWithUserUID:user.uid];
                                           }
                                       }];
        } else {
            [self updateDatabaseWithUserUID:user.key];
        }
    } else {
        [self.hud hideAnimated:YES];
    }
}

- (IBAction)tappedCancelButton:(id)sender
{
    [self dismissController];
}

- (IBAction)changedPhotoRequiredSwitch:(UISwitch *)sender {
    if (sender.isOn) {
        self.user.requiresPhoto = YES;
    } else {
        self.user.requiresPhoto = NO;
    }
}

#pragma mark - Helper Methods

- (BOOL)validInput
{
    User *user = self.user;

    NSString *company = [self textEnteredInTextField:FieldTag_Company forSection:SectionNumber_One];
    NSString *manager = [self textEnteredInTextField:FieldTag_Manager forSection:SectionNumber_One];
    
    if (user.type == UserType_Employee) {
        NSArray *existingProjects = [self.availableProjects allValues];
        for (NSInteger i = 0; i < self.numberOfProjectsShown; i++) {
            NSString *projectName = [self textEnteredInTextField:i forSection:SectionNumber_Two];
            if (![projectName vol_isStringEmpty] && ![existingProjects containsObject:projectName]) {
                [self presentValidationErrorAlertWithTitle:@"Invalid Project"
                                                   message:@"Please, select an existing project or create a new one in Projects."];
                return NO;
            }
        }
        
        NSArray *existingManagers = [self.availableManagers allValues];
        if (![existingManagers containsObject:manager]) {
            [self presentValidationErrorAlertWithTitle:@"Invalid Manager"
                                               message:@"Please, select an existing manager or create a new one in Users."];
            return NO;
        }
    }
    
    if (![user.email vol_isValidEmail]) {
        [self presentValidationErrorAlertWithTitle:@"Invalid Email"
                                           message:@"Please, verify the email format and try again."];
        return NO;
    } else if (![user.password vol_isValidPassword] && [user.key vol_isStringEmpty]) {
        [self presentValidationErrorAlertWithTitle:@"Invalid Password"
                                           message:@"Please, enter a password with at least 6 characters, one numeric digit and a letter"];
        return NO;
    } else if ([user.firstName vol_isStringEmpty] || [user.lastName vol_isStringEmpty]) {
        [self presentValidationErrorAlertWithTitle:@"No Name"
                                           message:@"A user has no name but this is not Game of Thrones. Enter one please."];
        return NO;
    } else if (user.type == UserType_Employee && [manager vol_isStringEmpty]) {
        [self presentValidationErrorAlertWithTitle:@"Manager Missing"
                                           message:@"Please, select a manager for this employee."];
        return NO;
    } else if (user.type != UserType_Admin && [company vol_isStringEmpty]) {
        [self presentValidationErrorAlertWithTitle:@"Client Missing"
                                           message:@"Please, enter a client name for this user."];
        return NO;
    }
    
    return YES;
}

- (NSString *)textEnteredInTextField:(FieldTag)textField
                          forSection:(SectionNumber)section
{
    UserDetailCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:textField inSection:section]];
    
    if (section == SectionNumber_One) {
        
        if (textField == FieldTag_FirstName) {
            return cell.firstNameTextField.text;
        } else if (textField == FieldTag_LastName) {
            return cell.lastNameTextField.text;
        } else if (textField == FieldTag_Email) {
            return cell.emailTextField.text;
        } else if (textField == FieldTag_Password) {
            return cell.passwordTextField.text;
        } else if (textField == FieldTag_Company) {
            return cell.companyTextField.text;
        } else if (textField == FieldTag_Manager) {
            return cell.managerTextField.text;
        }
        
    } else if (section == SectionNumber_Two) {
        
        return cell.projectTextField.text;
    
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
    
    __weak UserDetailTableViewController *weakSelf = self;
    
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return @"* all fields required";
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    User *user = self.user;
    
    if (section ==  SectionNumber_One) {
        if (user.type == UserType_Manager) {
            return 5;
        } else if (user.type == UserType_Employee) {
            return 7;
        } else if (user.type == UserType_Admin) {
            return 4;
        } else {
            return 0;
        }
    } else {
        return self.numberOfProjectsShown;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UserType loggedUserType = [AppState sharedInstance].type;
    
    NSString *reuseIdentifier;
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == SectionNumber_One) {
        if (row == FieldTag_FirstName) {
            reuseIdentifier = kFirstNameCell;
        } else if (row == FieldTag_LastName) {
            reuseIdentifier = kLastNameCell;
        } else if (row == FieldTag_Email) {
            reuseIdentifier = kEmailCell;
        } else if (row == FieldTag_Password) {
            reuseIdentifier = kPasswordCell;
        } else if (row == FieldTag_Company) {
            reuseIdentifier = kCompanyCell;
        } else if (row == FieldTag_Manager) {
            reuseIdentifier = kManagerCell;
        } else if (row == FieldTag_RequiresPhoto) {
            reuseIdentifier = kRequiresPhotoCell;
        } else {
            reuseIdentifier = @"";
        }
    } else if (section == SectionNumber_Two) {
        reuseIdentifier = kProjectCell;
    }
    
    User *user = self.user;
    
    UserDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (section == SectionNumber_One) {
        if (row == FieldTag_FirstName) {
            cell.firstNameTextField.text = user.firstName;
        } else if (row == FieldTag_LastName) {
            cell.lastNameTextField.text = user.lastName;
        } else if (row == FieldTag_Email) {
            if (!self.newUser) {
                cell.emailTextField.enabled = NO;
            }
            cell.emailTextField.text = user.email;
        } else if (row == FieldTag_Company) {
            MLPAutoCompleteTextField *companyField = cell.companyTextField;
            companyField.autoCompleteDataSource = self;
            companyField.autoCompleteTableAppearsAsKeyboardAccessory = YES;
            
            // Parent correction
            companyField.autoCompleteParentView = self.view;
            
            // Offset correction
            CGPoint pt = [companyField convertPoint:CGPointMake(0, companyField.frame.origin.y) toView:self.view];
            companyField.autoCompleteTableOriginOffset = CGSizeMake(0, pt.y);
            
            if ([companyField.text vol_isStringEmpty]) {
                companyField.text = self.availableCompanies[user.companyKey];
            }
        } else if (row == FieldTag_Manager) {
            MLPAutoCompleteTextField *managerField = cell.managerTextField;
            managerField.autoCompleteDataSource = self;
            managerField.autoCompleteTableAppearsAsKeyboardAccessory = YES;
            
            // Parent correction
            managerField.autoCompleteParentView = self.view;
            
            // Offset correction
            CGPoint pt = [managerField convertPoint:CGPointMake(0, managerField.frame.origin.y) toView:self.view];
            managerField.autoCompleteTableOriginOffset = CGSizeMake(0, pt.y);
            
            NSArray *userManagersKeys = [user.managers allKeys];
            if ([userManagersKeys count] > 0) {
                NSString *userManagerKey = userManagersKeys[0];
                if (self.availableManagers[userManagerKey]) {
                    managerField.text = self.availableManagers[userManagerKey];
                }
            }
        } else if (row == FieldTag_RequiresPhoto) {
            cell.requiresPhotoSwitch.on = user.requiresPhoto;
        }
        
        if (loggedUserType == UserType_Manager) {
            cell.firstNameTextField.enabled = NO;
            cell.lastNameTextField.enabled = NO;
            cell.emailTextField.enabled = NO;
            cell.companyTextField.enabled = NO;
            cell.managerTextField.enabled = NO;
            cell.requiresPhotoSwitch.enabled = NO;
        }
    } else {
        if (section == SectionNumber_Two) {
            MLPAutoCompleteTextField *projectField = cell.projectTextField;
            projectField.autoCompleteDataSource = self;
            projectField.autoCompleteDelegate = self;
            projectField.autoCompleteTableAppearsAsKeyboardAccessory = YES;
            
            // Parent correction
            projectField.autoCompleteParentView = self.view;
            
            // Offset correction
            CGPoint pt = [projectField convertPoint:CGPointMake(0, projectField.frame.origin.y) toView:self.view];
            projectField.autoCompleteTableOriginOffset = CGSizeMake(0, pt.y);
            
            if ([self.userProjectKeys count] > row) {
                projectField.text = self.availableProjects[self.userProjectKeys[row]];
            }
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionNumber_One) {
        // Hide the password row for existing users
        if (indexPath.row == FieldTag_Password && ![self.user.key vol_isStringEmpty]) {
            return 0.0f;
        }
    }
    
    return UITableViewAutomaticDimension;
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)[[textField superview] superview]];
    
    textField.text = @"";
    
    self.numberOfProjectsShown--;
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [textField resignFirstResponder];
    
    return NO;

}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    User *user = self.user;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)[[textField superview] superview]];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == SectionNumber_One) {
        if (row == FieldTag_FirstName) {
            user.firstName = textField.text;
        } else if (row == FieldTag_LastName) {
            user.lastName = textField.text;
        } else if (row == FieldTag_Email) {
            user.email = textField.text;
        } else if (row == FieldTag_Password) {
            user.password = textField.text;
        } else if (row == FieldTag_Company) {
            NSArray *companiesKeys = [self.availableManagers allKeysForObject:textField.text];
            
            if ([companiesKeys count] > 0) {
                NSString *companyKey = [companiesKeys firstObject];
                user.companyKey = companyKey;
            }
        } else if (row == FieldTag_Manager) {
            [user.managers removeAllObjects];
            NSArray *managersKeys = [self.availableManagers allKeysForObject:textField.text];
            
            if ([managersKeys count] > 0) {
                NSString *managerKey = [managersKeys firstObject];
                user.managers[managerKey] = @(YES);
            }
        }
    } else if (section == SectionNumber_Two) {
        
        // Erase text entered if it doesn't match an available project
        if (textField.tag == FieldTag_Project) {
            if (![[self.availableProjects allValues] containsObject:textField.text]) {
                textField.text = @"";
            }
        }
    }
}

#pragma mark - MLPAutoCompleteTextField delegate

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
 possibleCompletionsForString:(NSString *)string
            completionHandler:(void (^)(NSArray *))handler
{
    if (textField.tag == FieldTag_Company) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_async(queue, ^{
            NSArray *completions = [self.availableCompanies allValues];
            handler(completions);
        });
    } else if (textField.tag == FieldTag_Manager) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_async(queue, ^{
            NSArray *completions = [self.availableManagers allValues];
            handler(completions);
        });
    } else if (textField.tag == FieldTag_Project) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_async(queue, ^{
            NSArray *completions = [self.availableProjects allValues];
            handler(completions);
        });
    }
}

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField didSelectAutoCompleteString:(NSString *)selectedString withAutoCompleteObject:(id<MLPAutoCompletionObject>)selectedObject forRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.numberOfProjectsShown++;
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.numberOfProjectsShown-1 inSection:SectionNumber_Two]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self.delegate resetPresentingController];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
