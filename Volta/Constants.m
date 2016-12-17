//
//  Constants.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/9/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "Constants.h"

@implementation Constants

NSString *const NotificationKeysSignedIn = @"onSignInCompleted";

// Segues
NSString *const SeguesSignInToMainScreen = @"SignInToMainScreen";
NSString *const SeguesMainScreenToSignIn = @"MainScreenToSignIn";

NSString *const SeguesAddManager = @"AddManager";
NSString *const SeguesAddEmployee = @"AddEmployee";
NSString *const SeguesAddAdmin = @"AddAdmin";
NSString *const SeguesShowUserDetail = @"ShowUserDetail";

NSString *const SeguesAddProject = @"AddProject";
NSString *const SeguesShowProjectDetail = @"ShowProjectDetail";

NSString *const SeguesPresentWeeks = @"PresentWeeks";
NSString *const SeguesPresentDays = @"PresentDays";
NSString *const SeguesShowDayDetail = @"ShowDayDetail";

// View controllers
NSString *const kSideMenuViewController = @"SideMenuViewController";
NSString *const kUsersNavigationController = @"UsersNavigationController";
NSString *const kTimesheetsNavigationController = @"TimesheetsNavigationController";
NSString *const kProjectsNavigationController = @"ProjectsNavigationController";

// User Detail Cells
NSString *const kFirstNameCell = @"FirstNameCell";
NSString *const kLastNameCell = @"LastNameCell";
NSString *const kEmailCell = @"EmailCell";
NSString *const kPasswordCell = @"PasswordCell";
NSString *const kCompanyCell = @"CompanyCell";
NSString *const kManagerCell = @"ManagerCell";
NSString *const kProjectCell = @"ProjectCell";

// Project Detail Cells
NSString *const kProjectNameCell = @"ProjectNameCell";
NSString *const kProjectTotalDurationCell = @"ProjectTotalDurationCell";
NSString *const kProjectOrganizationCell = @"ProjectOrganizationCell";
NSString *const kProjectCompanyCell = @"ProjectCompanyCell";

// Timesheets
NSInteger const kNumberOfWeeksInPicker = 53; // Maximum number of weeks in a year

@end
