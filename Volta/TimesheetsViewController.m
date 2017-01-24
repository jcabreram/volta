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

@interface TimesheetsViewController ()

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

@end

@implementation TimesheetsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UserType currentUserType = [AppState sharedInstance].type;
    if (currentUserType == UserType_Employee) {
        self.navigationController.toolbarHidden = YES;
        [self.darkOverlay removeFromSuperview];
        self.shareButton.enabled = YES;
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
        [[[self.databaseRef child:@"employees"]
          child:@"members"]
         observeSingleEventOfType:FIRDataEventTypeValue
         withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
             if (snapshot.exists) {
                 self.availableEmployeeNames = snapshot.value;
                 
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
                     }];
                 }
             }
         }];
    } else if (currentUserType == UserType_Manager) {
        [[[[self.databaseRef child:@"users"]
           child:currentUserID]
          child:@"employees"]
         observeSingleEventOfType:FIRDataEventTypeValue
         withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
             if (snapshot.exists) {
                 self.availableEmployeeNames = snapshot.value;
                 
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
                     }];
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
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Submit Week" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self changeWeekToStatus:Status_Submitted];
        }]];
        
    } else if (state.type == UserType_Admin || state.type == UserType_Manager) {
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Approve" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self changeWeekToStatus:Status_Approved];
        }]];
        
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Don't Approve" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self changeWeekToStatus:Status_NotApproved];
        }]];
    }
    
    if (state.type == UserType_Admin) {
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
    [self copyReportFolderToDocuments];
    
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
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *htmlFilePath = [documentsDirectory stringByAppendingPathComponent:@"TimesheetReport/index.html"];

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
    
    // Create PDF from HTML
    
    NSURL *htmlFileURL = [NSURL fileURLWithPath:htmlFilePath];
    NSString *fileNameForPDF = [NSString stringWithFormat:@"Weekly timesheet for %@ (%@).pdf", employeeName, weekRange];
    NSString *pathForPDF = [documentsDirectory stringByAppendingPathComponent:fileNameForPDF];
    self.PDFCreator = [NDHTMLtoPDF createPDFWithURL:htmlFileURL
                                         pathForPDF:pathForPDF
                                           delegate:self
                                           pageSize:kPaperSizeA4
                                            margins:UIEdgeInsetsMake(0, 5, 0, 5)];
}

- (void)copyReportFolderToDocuments
{
    NSString *directory = @"TimesheetReport";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *documentDBFolderPath = [documentsDirectory stringByAppendingPathComponent:directory];
    NSString *resourceDBFolderPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:directory];
    
    if (![fileManager fileExistsAtPath:documentDBFolderPath]) {
        [fileManager createDirectoryAtPath:documentDBFolderPath
               withIntermediateDirectories:NO
                                attributes:nil
                                     error:&error];
    }
    
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:resourceDBFolderPath
                                                         error:&error];
    
    NSString *indexPath = [documentDBFolderPath stringByAppendingPathComponent:@"index.html"];
    [fileManager removeItemAtPath:indexPath error:&error];
    
    for (NSString *fileName in fileList) {
        NSString *newFilePath = [documentDBFolderPath stringByAppendingPathComponent:fileName];
        NSString *oldFilePath = [resourceDBFolderPath stringByAppendingPathComponent:fileName];
        if (![fileManager fileExistsAtPath:newFilePath]) {
            [fileManager copyItemAtPath:oldFilePath toPath:newFilePath error:&error];
        }
    }
}

- (void)showTimesheetForUserWithID:(NSString *)userID
{
    AppState *state = [AppState sharedInstance];
    self.selectedEmployeeKey = userID;
    
    [[[self.databaseRef child:@"users"] child:userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSLog(@"");
        if (snapshot.exists) {
            state.timesheetKey = snapshot.value[@"timesheet"];
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationKeysTimesheetDidChange object:nil];
        }
    }];
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
    
    if (currentUserType == UserType_Manager && self.week.status == Status_Approved) {
        self.shareButton.enabled = NO;
    } else {
        self.shareButton.enabled = YES;
    }
}

#pragma mark NDHTMLtoPDFDelegate

- (void)HTMLtoPDFDidSucceed:(NDHTMLtoPDF*)htmlToPDF
{
    NSString *result = [NSString stringWithFormat:@"HTMLtoPDF did succeed (%@ / %@)", htmlToPDF, htmlToPDF.PDFpath];
    NSLog(@"%@",result);
    
    self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:htmlToPDF.PDFpath]];
    self.interactionController.delegate = self;
    CGRect navRect = self.view.frame;
    [self.interactionController presentOptionsMenuFromRect:navRect inView:self.view animated:YES];
    
}

- (void)HTMLtoPDFDidFail:(NDHTMLtoPDF*)htmlToPDF
{
    NSString *result = [NSString stringWithFormat:@"HTMLtoPDF did fail (%@)", htmlToPDF];
    NSLog(@"%@",result);
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

@end
