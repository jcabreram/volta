//
//  SideMenuViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/9/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "Constants.h"
#import "SideMenuViewController.h"
#import "SideMenuViewCell.h"
#import "AppState.h"
#import "UIViewController+LGSideMenuController.h"
#import "TimesheetsViewController.h"
#import "MainViewController.h"

typedef NS_ENUM (NSInteger, SideMenuEntry) {
    SideMenuEntry_DisplayName,
    SideMenuEntry_Empty01,
    SideMenuEntry_Timesheets,
    SideMenuEntry_Activities,
    SideMenuEntry_Holidays,
    SideMenuEntry_Expenses,
    SideMenuEntry_Projects,
    SideMenuEntry_Empty02,
    SideMenuEntry_LogOut,
};

@import Firebase;

@interface SideMenuViewController ()

@property (strong, nonatomic) NSArray *titlesArray;

@end

@implementation SideMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *displayName = [AppState sharedInstance].displayName;
    
    // -----
    
    _titlesArray = @[displayName,
                     @"",
                     @"Timesheets",
                     @"Activities",
                     @"Holidays",
                     @"Expenses",
                     @"Projects",
                     @"",
                     @"Log Out"];
    
    // -----
    
    self.tableView.contentInset = UIEdgeInsetsMake(44.f, 0.f, 44.f, 0.f);
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _titlesArray.count;
}

#pragma mark - UITableView Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SideMenuViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = _titlesArray[indexPath.row];
    cell.separatorView.hidden = indexPath.row <= 1 || indexPath.row >= 7 || indexPath.row == _titlesArray.count - 1;
    cell.userInteractionEnabled = indexPath.row != 1 || indexPath.row != 7;
    cell.tintColor = _tintColor;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == 1 ? 22.f : 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    
    if (row == SideMenuEntry_DisplayName) { // 0
        [[self sideMenuController] hideLeftViewAnimated:YES completionHandler:nil];
    } else if (row == SideMenuEntry_Empty01) { // 1
        // Empty
    } else if (row == SideMenuEntry_Timesheets) { // 2
        UINavigationController *presentedNavigationController = (UINavigationController *)[self sideMenuController].rootViewController;
        
        // If the presented controller is different from selection
        if (![presentedNavigationController.childViewControllers[0] isKindOfClass:[TimesheetsViewController class]]) {
            UINavigationController *timesheetsNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:kTimesheetsNavigationController];
            [self sideMenuController].rootViewController = timesheetsNavigationController;
        }
        
        [[self sideMenuController] hideLeftViewAnimated:YES completionHandler:nil];
    } else if (row >= SideMenuEntry_Activities && row <= SideMenuEntry_Projects) { // 3 to 6
        UIViewController *viewController = [UIViewController new];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        viewController.view.backgroundColor = [UIColor whiteColor];
        viewController.title = _titlesArray[indexPath.row];
        [self sideMenuController].rootViewController = navigationController;
        
        [[self sideMenuController] hideLeftViewAnimated:YES completionHandler:nil];
    } else if (indexPath.row == SideMenuEntry_Empty02) { // 7
        // Empty
    } else if (indexPath.row == SideMenuEntry_LogOut) { // 8
        FIRAuth *firebaseAuth = [FIRAuth auth];
        NSError *signOutError;
        BOOL status = [firebaseAuth signOut:&signOutError];
        if (!status) {
            NSLog(@"Error signing out: %@", signOutError);
            return;
        }
        [AppState sharedInstance].signedIn = false;
        [(MainViewController *)self.sideMenuController logout];
    }
}


@end
