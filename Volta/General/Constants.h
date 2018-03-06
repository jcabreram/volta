//
//  Constants.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/9/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//


@interface Constants : NSObject

// Notifications
extern NSString *const NotificationKeysSignedIn;
extern NSString *const NotificationKeysTimesheetDidChange;

// Segues
extern NSString *const SeguesSignInToMainScreen;
extern NSString *const SeguesMainScreenToSignIn;

extern NSString *const SeguesAddManager;
extern NSString *const SeguesAddEmployee;
extern NSString *const SeguesAddAdmin;
extern NSString *const SeguesShowUserDetail;

extern NSString *const SeguesAddProject;
extern NSString *const SeguesShowProjectDetail;

extern NSString *const SeguesPresentWeeks;
extern NSString *const SeguesPresentDays;
extern NSString *const SeguesShowDayDetail;

// View controllers
extern NSString *const kSideMenuViewController;
extern NSString *const kUsersNavigationController;
extern NSString *const kTimesheetsNavigationController;
extern NSString *const kProjectsNavigationController;

// User Detail Cells
extern NSString *const kFirstNameCell;
extern NSString *const kLastNameCell;
extern NSString *const kEmailCell;
extern NSString *const kPasswordCell;
extern NSString *const kCompanyCell;
extern NSString *const kManagerCell;
extern NSString *const kRequiresPhotoCell;
extern NSString *const kProjectCell;

// Project Detail Cells
extern NSString *const kProjectNameCell;
extern NSString *const kProjectTotalDurationCell;
extern NSString *const kProjectOrganizationCell;
extern NSString *const kProjectCompanyCell;

// Timesheets
extern NSInteger const kNumberOfWeeksInPicker;


@end
