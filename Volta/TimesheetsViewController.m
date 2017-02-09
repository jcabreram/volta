//
//  TimesheetsViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/10/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "TimesheetsViewController.h"
#import "Constants.h"
#import "WeeksCollectionViewController.h"
#import "DaysTableViewController.h"
#import "AppState.h"
#import "TimesheetWeek.h"
#import "ActionSheetPicker.h"
#import "MBProgressHUD.h"
#import "UIColor+VOLcolors.h"
#import "UIImage+VOLImage.h"

@import EPSignature;
@import AVFoundation;

@interface TimesheetsViewController () <EPSignatureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) WeeksCollectionViewController *weeksVC;
@property (nonatomic, strong) DaysTableViewController *daysVC;

@property (weak, nonatomic) IBOutlet UILabel *allocatedHoursLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectEmployeeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;
@property (weak, nonatomic) IBOutlet UIView *darkOverlay;

@property (nonatomic) UIDocumentInteractionController *interactionController;

@property (nonatomic, strong) FIRDatabaseReference *databaseRef;
@property (nonatomic, assign) FIRDatabaseHandle availableCompaniesHandle;
@property (nonatomic, assign) FIRDatabaseHandle availableManagersHandle;
@property (nonatomic, assign) FIRDatabaseHandle availableProjectsHandle;

@property (nonatomic, strong) NSMutableDictionary *availableEmployeeNames;
@property (nonatomic, strong) NSMutableDictionary *availableEmployees;
@property (nonatomic, strong) NSMutableDictionary *availableCompanies;
@property (nonatomic, strong) NSMutableDictionary *availableManagers;
@property (nonatomic, strong) NSMutableDictionary *availableProjects;

@property (nonatomic, strong) NSString *selectedEmployeeKey;

@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@end

@implementation TimesheetsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UserType currentUserType = [AppState sharedInstance].type;
    if (currentUserType == UserType_Employee) {
        self.navigationController.toolbarHidden = YES;
        [self.darkOverlay removeFromSuperview];
        self.shareButton.enabled = YES;
    } else {
        self.shareButton.enabled = NO;
    }
    
    // Change the navigation bar color to gradient
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageLayerForGradientBackgroundWithBounds:self.navigationController.navigationBar.bounds] forBarMetrics:UIBarMetricsDefault];
    
    if (currentUserType == UserType_Manager) {
        [self verifySignatureInStorage];
    }
    
    self.availableEmployees = [[NSMutableDictionary alloc] init];
    self.availableManagers = [[NSMutableDictionary alloc] init];
    self.availableCompanies = [[NSMutableDictionary alloc] init];
    self.availableProjects = [[NSMutableDictionary alloc] init];
    
    [self configureDatabase];
}

- (void)configureDatabase {
    self.databaseRef = [[FIRDatabase database] reference];
    
    NSString *currentUserID = [AppState sharedInstance].userID;
    UserType currentUserType = [AppState sharedInstance].type;
    
    if (currentUserType == UserType_Admin) {
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        [[[self.databaseRef child:@"employees"]
          child:@"members"]
         observeSingleEventOfType:FIRDataEventTypeValue
         withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
             if (snapshot.exists) {
                 self.availableEmployeeNames = snapshot.value;
                 
                 NSInteger counter = 1;
                 for (NSString *userKey in self.availableEmployeeNames) {
                     [[[self.databaseRef child:@"users"] child:userKey] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                         if (snapshot.exists) {
                             NSString *firstName = snapshot.value[@"first_name"];
                             NSString *lastName = snapshot.value[@"last_name"];
                             NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                             self.availableEmployeeNames[userKey] = fullName;
                             self.availableEmployees[userKey] = snapshot.value;
                         } else {
                             [self.availableEmployeeNames removeObjectForKey:userKey];
                         }
                         
                         if (counter == self.availableEmployeeNames.count) {
                             [self.hud hideAnimated:YES];
                         }
                     }];
                     counter++;
                 }
             }
         }];
    } else if (currentUserType == UserType_Manager) {
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        [[[[self.databaseRef child:@"users"]
           child:currentUserID]
          child:@"employees"]
         observeSingleEventOfType:FIRDataEventTypeValue
         withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
             if (snapshot.exists) {
                 self.availableEmployeeNames = snapshot.value;
                 
                 NSInteger counter = 1;
                 for (NSString *userKey in self.availableEmployeeNames) {
                     [[[self.databaseRef child:@"users"] child:userKey] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                         if (snapshot.exists) {
                             NSString *firstName = snapshot.value[@"first_name"];
                             NSString *lastName = snapshot.value[@"last_name"];
                             NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                             self.availableEmployeeNames[userKey] = fullName;
                             self.availableEmployees[userKey] = snapshot.value;
                         } else {
                             [self.availableEmployeeNames removeObjectForKey:userKey];
                         }
                         
                         if (counter == self.availableEmployeeNames.count) {
                             [self.hud hideAnimated:YES];
                         }
                     }];
                     counter++;
                 }
             }
         }];
    }
    
    self.availableManagersHandle = [[[self.databaseRef child:@"managers"] child:@"members"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        [[[[self.databaseRef child:@"users"] queryOrderedByKey] queryEqualToValue:snapshot.key] observeSingleEventOfType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            NSDictionary<NSString *, NSString *> *userDict = snapshot.value;
            NSString *fullName = [NSString stringWithFormat:@"%@ %@", userDict[@"first_name"], userDict[@"last_name"]];
            self.availableManagers[snapshot.key] = fullName;
        }];
     }];
    
    self.availableCompaniesHandle = [[self.databaseRef child:@"companies"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSDictionary<NSString *, NSString *> *childDict = snapshot.value;
        id expectedNameString = childDict[@"name"];
        id expectedKeyString = snapshot.key;
        if (expectedNameString != nil && [expectedNameString isKindOfClass:[NSString class]] && [expectedKeyString isKindOfClass:[NSString class]]) {
            self.availableCompanies[(NSString *)expectedKeyString] = expectedNameString;
        }
    }];
    
    self.availableProjectsHandle = [[self.databaseRef child:@"projects"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSDictionary<NSString *, NSString *> *childDict = snapshot.value;
        id expectedNameString = childDict[@"name"];
        id expectedKeyString = snapshot.key;
        if (expectedNameString != nil && [expectedNameString isKindOfClass:[NSString class]] && [expectedKeyString isKindOfClass:[NSString class]]) {
            self.availableProjects[(NSString *)expectedKeyString] = expectedNameString;
        }
    }];
}

- (void)dealloc
{
    [[self.databaseRef child:@"companies"] removeObserverWithHandle:self.availableCompaniesHandle];
    [[self.databaseRef child:@"managers"] removeObserverWithHandle:self.availableManagersHandle];
    [[self.databaseRef child:@"projects"] removeObserverWithHandle:self.availableManagersHandle];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueName = segue.identifier;
    
    if ([segueName isEqualToString:SeguesPresentWeeks]) {
        self.weeksVC = (WeeksCollectionViewController *)segue.destinationViewController;
    } else if ([segueName isEqualToString:SeguesPresentDays]) {
        self.daysVC = (DaysTableViewController *)segue.destinationViewController;
    }
    
    self.weeksVC.delegate = self.daysVC;
    self.weeksVC.actionSheetDelegate = self;
    self.daysVC.delegate = self;
}

- (IBAction)shareButtonPressed:(UIBarButtonItem *)sender {
    AppState *state = [AppState sharedInstance];
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (state.type == UserType_Employee) {
        
        if (self.week.status == Status_Submitted) {
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Edit Week" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self changeWeekToStatus:Status_NotSubmitted];
            }]];
        } else {
            [actionSheet addAction:[UIAlertAction actionWithTitle:@"Submit Week" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self changeWeekToStatus:Status_Submitted];
            }]];
        }
        
    } else if (state.type == UserType_Manager) {
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Approve" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self changeWeekToStatus:Status_Approved];
            [self updateProjectsCurrentDuration];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Deny" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self changeWeekToStatus:Status_NotApproved];
        }]];
    }
    
    if (state.type == UserType_Admin) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Change to Not Submitted" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self changeWeekToStatus:Status_NotSubmitted];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Change to Submitted" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self changeWeekToStatus:Status_Submitted];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Export to PDF" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self exportWeekToPDF];
        }]];
    }
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [actionSheet setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popPresenter = [actionSheet popoverPresentationController];
    popPresenter.barButtonItem = sender;
    popPresenter.sourceView = self.view;
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)changeWeekToStatus:(Status)status
{
    self.week.status = status;
    
    [[[[[self.databaseRef child:@"timesheets"]
        child:[AppState sharedInstance].timesheetKey]
       child:[@(self.week.year) stringValue]]
      child:[@(self.week.weekNumber) stringValue]]
     setValue:@(status)];
    
    if (status == Status_Approved) {
        self.shareButton.enabled = NO;
    }
}

- (IBAction)selectEmployeeButtonPressed:(id)sender {
    NSArray *employeeNames = [self.availableEmployeeNames allValues];
    if (!employeeNames) {
        employeeNames = [[NSArray alloc] init];
    }
    NSArray *orderedEmployeeNames = [employeeNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    ActionSheetStringPicker *picker = [[ActionSheetStringPicker alloc] initWithTitle:@"Select an Employee"
                                                                                rows:orderedEmployeeNames
                                                                    initialSelection:0
                                                                           doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                                                               
                                                                               NSArray *employeeKeys = [self.availableEmployeeNames allKeysForObject:selectedValue];
                                                                               
                                                                               if ([employeeKeys count] > 0) {
                                                                                   NSString *employeeKey = [employeeKeys firstObject];
                                                                                   [self showTimesheetForUserWithID:employeeKey];
                                                                                   
                                                                                   self.selectEmployeeBarButtonItem.title = selectedValue;
                                                                                   [self.darkOverlay removeFromSuperview];
                                                                                   self.shareButton.enabled = YES;
                                                                               }
                                                                           }
                                                                         cancelBlock:nil
                                                                              origin:sender];
    
    [picker showActionSheetPicker];
}

- (void)exportWeekToPDF
{
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self copyReportFolderToTemporalDirectory];
    
    TimesheetWeek *week = self.week;
    
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    
    NSDate *startDate = [self.week startingDate];
    NSString *weekRange = [self.week stringWithDateRange];
    
    NSString *employeeName = self.availableEmployeeNames[self.selectedEmployeeKey];
    NSDictionary *employeeData = self.availableEmployees[self.selectedEmployeeKey];
    NSString *managerKey = [[employeeData[@"managers"] allKeys] firstObject];
    NSString *manager = self.availableManagers[managerKey];
    NSString *companyKey = employeeData[@"company"];
    NSString *company = self.availableCompanies[companyKey];
    NSString *status = week.statusString;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE dd"];
    
    NSMutableString *dayHoursProjectsRows = [[NSMutableString alloc] init];
    
    for (NSInteger i = 0; i < 7; i++) {
        NSDate *rowDate = [cal dateByAddingUnit:NSCalendarUnitDay value:i toDate:startDate options:0];
        NSDictionary *dayProjects = [week projectsForDay:i];
        
        NSString *dayHoursString;
        if (![week.hoursPerDay[i] isEqual:[NSNull null]] && [week.hoursPerDay[i] integerValue] > 0) {
            dayHoursString = [week.hoursPerDay[i] stringValue];
        } else {
            dayHoursString = @"-";
        }
        [dayHoursProjectsRows appendFormat:@"<tr><td>%@</td><td>%@</td><td>", [dateFormatter stringFromDate:rowDate], dayHoursString];
        
        for (NSString *projectKey in dayProjects) {
            if ([dayProjects[projectKey] integerValue] > 0) {
                [dayHoursProjectsRows appendFormat:@"%@ - %@<br>", self.availableProjects[projectKey], dayProjects[projectKey]];
            }
        }
        [dayHoursProjectsRows appendString:@"</td></tr>"];
    }
    
    [dayHoursProjectsRows appendFormat:@"<tr><td>Total</td><td>%@</td><td></td></tr>", [week allocatedHours]];
    
    NSString *tempDir = NSTemporaryDirectory();
    NSString *htmlFilePath = [tempDir stringByAppendingPathComponent:@"TimesheetReport/index.html"];

    NSMutableString *html = [[NSString stringWithContentsOfFile:htmlFilePath encoding:NSUTF8StringEncoding error:nil] mutableCopy];
    NSRange htmlRange = NSMakeRange(0, [html length]);
    
    [html replaceOccurrencesOfString:@"%weekRange%" withString:weekRange options:NSCaseInsensitiveSearch range:htmlRange];
    [html replaceOccurrencesOfString:@"%dayHoursProjectsRows%" withString:dayHoursProjectsRows options:NSCaseInsensitiveSearch range:htmlRange];
    [html replaceOccurrencesOfString:@"%employeeName%" withString:employeeName options:NSCaseInsensitiveSearch range:htmlRange];
    [html replaceOccurrencesOfString:@"%clientName%" withString:company options:NSCaseInsensitiveSearch range:htmlRange];
    [html replaceOccurrencesOfString:@"%managerName%" withString:manager options:NSCaseInsensitiveSearch range:htmlRange];
    [html replaceOccurrencesOfString:@"%status%" withString:status options:NSCaseInsensitiveSearch range:htmlRange];
    
    NSError *error;
    [html writeToFile:htmlFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        NSLog(@"Modified HTML at %@", htmlFilePath);
    }
    
    // Download signature from Firebase Storage
    NSString *signatureFilename = [NSString stringWithFormat:@"%@.png", managerKey];
    
    FIRStorageReference *signatureRef = [[[[FIRStorage storage] reference] child:@"signatures"] child:signatureFilename];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *signatureDirectoryPath = [tempDir stringByAppendingPathComponent:@"TimesheetReport/"];
    NSString *signaturePath = [signatureDirectoryPath stringByAppendingPathComponent:@"signature.png"];
    NSURL *localURL = [NSURL fileURLWithPath:signaturePath];
    [fileManager removeItemAtPath:signaturePath error:&error];

    [signatureRef writeToFile:localURL completion:^(NSURL * _Nullable URL, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error while downloading signature");
            
            NSString *message = [NSString stringWithFormat:@"%@ will be asked to create a signature in the next login.", manager];
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"No Signature From Manager"
                                                                                message:message
                                                                         preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:nil];
            [errorAlert addAction:okAction];
            [self presentViewController:errorAlert animated:YES completion:nil];
            
            [self.hud hideAnimated:YES];
        } else {
            // Create PDF from HTML
            NSURL *htmlFileURL = [NSURL fileURLWithPath:htmlFilePath];
            NSString *fileNameForPDF = [NSString stringWithFormat:@"Weekly timesheet for %@ (%@).pdf", employeeName, weekRange];
            NSString *pathForPDF = [tempDir stringByAppendingPathComponent:fileNameForPDF];
            self.PDFCreator = [NDHTMLtoPDF createPDFWithURL:htmlFileURL
                                                 pathForPDF:pathForPDF
                                                   delegate:self
                                                   pageSize:kPaperSizeA4
                                                    margins:UIEdgeInsetsMake(0, 5, 0, 5)];
        }
    }];
}

- (void)copyReportFolderToTemporalDirectory
{
    NSString *directory = @"TimesheetReport";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *tempDir = NSTemporaryDirectory();
    NSString *tempTimesheetDir = [tempDir stringByAppendingPathComponent:directory];
    NSString *resourceTimesheetDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:directory];
    
    if (![fileManager fileExistsAtPath:tempTimesheetDir]) {
        [fileManager createDirectoryAtPath:tempTimesheetDir
               withIntermediateDirectories:NO
                                attributes:nil
                                     error:&error];
    }
    
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:resourceTimesheetDir
                                                         error:&error];
    
    NSString *indexPath = [tempTimesheetDir stringByAppendingPathComponent:@"index.html"];
    [fileManager removeItemAtPath:indexPath error:&error];
    
    for (NSString *fileName in fileList) {
        NSString *newFilePath = [tempTimesheetDir stringByAppendingPathComponent:fileName];
        NSString *oldFilePath = [resourceTimesheetDir stringByAppendingPathComponent:fileName];
        if (![fileManager fileExistsAtPath:newFilePath]) {
            [fileManager copyItemAtPath:oldFilePath toPath:newFilePath error:&error];
        }
    }
}

- (void)showTimesheetForUserWithID:(NSString *)userID
{
    AppState *state = [AppState sharedInstance];
    self.selectedEmployeeKey = userID;
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[[self.databaseRef child:@"users"] child:userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        [self.hud hideAnimated:YES];
        if (snapshot.exists) {
            state.timesheetKey = snapshot.value[@"timesheet"];
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationKeysTimesheetDidChange object:nil];
        }
    }];
}

- (void)verifySignatureInStorage
{
    NSString *userID = [AppState sharedInstance].userID;
    NSString *signatureFilename = [NSString stringWithFormat:@"%@.png", userID];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    FIRStorageReference *storageRef = [[[[FIRStorage storage] reference] child:@"signatures"] child:signatureFilename];
    
    [storageRef metadataWithCompletion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
        [hud hideAnimated:YES];
        
        if (!error) {
            return;
        } else {
            FIRStorageErrorCode errorCode = error.code;
            
            if (errorCode == FIRStorageErrorCodeObjectNotFound) {
                [self showSignatureVC];
            }
        }
    }];
}

- (void)showSignatureVC
{
    NSString *userName = [AppState sharedInstance].displayName;
    
    EPSignatureViewController *signatureVC = [[EPSignatureViewController alloc] initWithSignatureDelegate:self showsDate:YES showsSaveSignatureOption:NO];
    signatureVC.subtitleText = @"This signature will be used to approve timesheets within Volta";
    signatureVC.tintColor = [UIColor voltaBlue];
    signatureVC.title = userName;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:signatureVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)uploadImageToFirebaseStorage:(NSData *)data
{
    NSString *userID = [AppState sharedInstance].userID;
    NSString *signatureFilename = [NSString stringWithFormat:@"%@.png", userID];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"Saving signature...";
                          
    FIRStorageReference *storageRef = [[[[FIRStorage storage] reference] child:@"signatures"] child:signatureFilename];
    FIRStorageMetadata *uploadMetadata = [[FIRStorageMetadata alloc] init];
    uploadMetadata.contentType = @"image/png";
    
    [storageRef putData:data
               metadata:uploadMetadata
             completion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
                 [hud hideAnimated:YES];
                 if (error) {
                     NSLog(@"Error uploading image: %@", error.localizedDescription);
                     
                     UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error While Saving Image"
                                                                                         message:error.localizedDescription
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                     UIAlertAction *tryAgainAction = [UIAlertAction actionWithTitle:@"Try again"
                                                                              style:UIAlertActionStyleDefault
                                                                            handler:^(UIAlertAction * _Nonnull action) {
                                                                                [self showSignatureVC];
                                                                            }];
                     [errorAlert addAction:tryAgainAction];
                     [self presentViewController:errorAlert animated:YES completion:nil];
                 } else {
                     NSLog(@"Upload complete! Image metadata: %@", metadata);
                     
                     UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"Signature Saved"
                                                                                           message:@"Your signature will be used for approving timesheets"
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                     UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:nil];
                     [successAlert addAction:okAction];
                     [self presentViewController:successAlert animated:YES completion:nil];
                     
                 }
             }];
}

- (void)showCamera
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        // There is not a camera on this device, so show alert.
        UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"No Camera Available"
                                                                            message:@"A camera is required to upload the timesheet's photo"
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [errorAlert addAction:okAction];
        [self presentViewController:errorAlert animated:YES completion:nil];
    } else {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusDenied)
        {
            // Denies access to camera, alert the user.
            // The user has previously denied access. Remind the user that we need camera access to be useful.
            UIAlertController *alertController =
            [UIAlertController alertControllerWithTitle:@"Unable to access the Camera"
                                                message:@"To enable access, go to Settings > Privacy > Camera and turn on Camera access for this app."
                                         preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:ok];
            
            [self presentViewController:alertController animated:YES completion:nil];
        }
        else if (authStatus == AVAuthorizationStatusNotDetermined)
            // The user has not yet been presented with the option to grant access to the camera hardware.
            // Ask for it.
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                // If access was denied, we do not set the setup error message since access was just denied.
                if (granted)
                {
                    // Allowed access to camera, go ahead and present the UIImagePickerController.
                    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
                }
            }];
        else
        {
            // Allowed access to camera, go ahead and present the UIImagePickerController.
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
        }
    }
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.showsCameraControls = YES;
    imagePickerController.delegate = self;
    imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    _imagePickerController = imagePickerController; // we need this for later
    
    [self presentViewController:self.imagePickerController animated:YES completion:^{
        //.. done presenting
    }];
}

- (void)updateProjectsCurrentDuration
{
    NSArray *projectsArray = [self.week arrayWithProjects];
    NSMutableDictionary *timeDifferences = [NSMutableDictionary new];
    
    for (NSDictionary *dayProjects in projectsArray) {
        for (NSString *projectKey in dayProjects) {
            if (timeDifferences[projectKey]) {
                double previous = [timeDifferences[projectKey] doubleValue];
                double new = [dayProjects[projectKey] doubleValue];
                double total = new + previous;
                timeDifferences[projectKey] = @(total);
            } else {
                timeDifferences[projectKey] = dayProjects[projectKey];
            }
        }
    }
    
    NSArray *timeDifferencesKeys = [timeDifferences allKeys];
    
    for (NSInteger i = 0; i < timeDifferences.count; i++) {
        NSString *projectKey = timeDifferencesKeys[i];
        
        // Get the current_duration of the project to update it
        [[[[self.databaseRef child:@"projects"] child:projectKey] child:@"current_duration"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            double currentDuration = 0.0;
            
            if (snapshot.exists) {
                currentDuration = [snapshot.value doubleValue];
            }
            
            double difference = [timeDifferences[projectKey] doubleValue];
            NSNumber *updatedDuration = @(currentDuration + difference);
            
            // Update the list of projects for the week
            [[[[self.databaseRef
                child:@"projects"]
               child:projectKey]
              child:@"current_duration"] setValue:updatedDuration];
        }];
    }
}

- (IBAction)tappedPhotoButton:(UIButton *)sender {
    [self showCamera];
}

#pragma mark - Days table view delegate

- (void)updateAllocatedHoursWithNumber:(NSNumber *)allocatedHours
{
    self.allocatedHoursLabel.text = [allocatedHours stringValue];
}

#pragma mark - Weeks Collection Action Sheet delegate

- (void)chosenWeekChangedToWeek:(TimesheetWeek *)week
{
    self.week = week;
    UserType currentUserType = [AppState sharedInstance].type;
    
    switch (currentUserType) {
        case UserType_Employee:
            if (self.week.status == Status_Approved) {
                self.shareButton.enabled = NO;
            } else {
                self.shareButton.enabled = YES;
            }
            break;
            
        case UserType_Manager:
            if (self.week.status == Status_Approved || !self.selectedEmployeeKey) {
                self.shareButton.enabled = NO;
            } else {
                self.shareButton.enabled = YES;
            }
            break;
            
        case UserType_Admin:
            self.shareButton.enabled = YES;
            break;
    }
}

- (void)weekStatusChangedTo:(Status)status
{
    self.week.status = status;
}

#pragma mark - NDHTMLtoPDFDelegate

- (void)HTMLtoPDFDidSucceed:(NDHTMLtoPDF*)htmlToPDF
{
    NSString *result = [NSString stringWithFormat:@"HTMLtoPDF did succeed (%@ / %@)", htmlToPDF, htmlToPDF.PDFpath];
    NSLog(@"%@",result);
    
    [self.hud hideAnimated:YES];
    
    self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:htmlToPDF.PDFpath]];
    self.interactionController.delegate = self;
    CGRect navRect = self.view.frame;
    [self.interactionController presentOptionsMenuFromRect:navRect inView:self.view animated:YES];
}

- (void)HTMLtoPDFDidFail:(NDHTMLtoPDF*)htmlToPDF
{
    NSString *result = [NSString stringWithFormat:@"PDF creation failed (%@)", htmlToPDF];
    NSLog(@"%@",result);
    [self.hud hideAnimated:YES];
    
    UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:@"Export to PDF Error"
                                                                          message:result
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okConfirmation = [UIAlertAction actionWithTitle:@"OK"
                                                             style:UIAlertActionStyleDefault
                                                           handler:nil];
    [confirmation addAction:okConfirmation];
    [self presentViewController:confirmation animated:YES completion:nil];
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self;
}

- (UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller
{
    return self.view;
}

- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController *)controller
{
    return self.view.frame;
}

#pragma mark - EPSignature delegate

- (void)epSignature:(EPSignatureViewController *)_ didCancel:(NSError *)error {
    NSLog(@"user cancelled");
}

- (void)epSignature:(EPSignatureViewController *)_ didSign:(UIImage *)signatureImage boundingRect:(CGRect)boundingRect
{
    NSLog(@"%@", signatureImage);
    
    // We cut the top half off
    CGImageRef tmpImgRef = signatureImage.CGImage;
    CGImageRef bottomImgRef = CGImageCreateWithImageInRect(tmpImgRef, CGRectMake(0, signatureImage.size.height / 2.0,  signatureImage.size.width, signatureImage.size.height / 2.0));
    UIImage *bottomImage = [UIImage imageWithCGImage:bottomImgRef];
    CGImageRelease(bottomImgRef);
    
    NSData *imageData = UIImagePNGRepresentation(bottomImage);
    [self uploadImageToFirebaseStorage:imageData];
}


#pragma mark - UIImagePickerControllerDelegate

// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Dismiss the image picker.
    [self dismissViewControllerAnimated:YES completion:^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        
        UIImage *scaledImage = [image resizeWithMaxDimension:1000.0]; // Increase for better quality. 1500 is more than enough.
        
        NSData *data = UIImageJPEGRepresentation(scaledImage, 0.7);
        
        NSString *timesheetID = [AppState sharedInstance].timesheetKey;
        NSString *yearString = [@(self.week.year) stringValue];
        NSString *weekNumberString = [@(self.week.weekNumber) stringValue];
        NSString *signatureFilename = [NSString stringWithFormat:@"%@.jpg", weekNumberString];
        
        hud.label.text = @"Uploading photo...";
        
        FIRStorageReference *storageRef = [[[[[[FIRStorage storage] reference] child:@"ts_photos"] child:timesheetID] child:yearString] child:signatureFilename];
        FIRStorageMetadata *uploadMetadata = [[FIRStorageMetadata alloc] init];
        uploadMetadata.contentType = @"image/jpeg";
        
        [storageRef putData:data
                   metadata:uploadMetadata
                 completion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
                     [hud hideAnimated:YES];
                     if (error) {
                         NSLog(@"Error uploading image: %@", error.localizedDescription);
                         
                         UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error While Saving Image"
                                                                                             message:error.localizedDescription
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                         UIAlertAction *tryAgainAction = [UIAlertAction actionWithTitle:@"Try again"
                                                                                  style:UIAlertActionStyleDefault
                                                                                handler:^(UIAlertAction * _Nonnull action) {
                                                                                    [self showSignatureVC];
                                                                                }];
                         [errorAlert addAction:tryAgainAction];
                         [self presentViewController:errorAlert animated:YES completion:nil];
                     } else {
                         NSLog(@"Upload complete! Image metadata: %@", metadata);
                         
                         UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"Photo Uploaded!"
                                                                                               message:@"This photo will be attached to your timesheet once you submit it."
                                                                                        preferredStyle:UIAlertControllerStyleAlert];
                         UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:nil];
                         [successAlert addAction:okAction];
                         [self presentViewController:successAlert animated:YES completion:nil];
                     }
                 }];
    }];
    
    self.imagePickerController = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        //.. done dismissing
    }];
}

@end
