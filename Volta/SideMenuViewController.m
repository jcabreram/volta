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
#import "ProjectsTableViewController.h"
#import "UsersTableViewController.h"

@interface SideMenuViewController ()

@property (strong, nonatomic) NSMutableArray *titlesArray;

@end

@implementation SideMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppState *state = [AppState sharedInstance];
    
    NSString *displayName = [AppState sharedInstance].displayName;
    
    // -----
    
    self.titlesArray = [@[displayName,
                          @"",
                          @"Timesheets"] mutableCopy];
    
    if (state.type == UserType_Admin || state.type == UserType_Employee) {
        [self.titlesArray addObject:@"Projects"];
    }
    
    if (state.type == UserType_Admin) {
        [self.titlesArray addObject:@"Users"];
    }
    
    [self.titlesArray addObjectsFromArray:@[@"",
                                            @"Log Out"]];
    
    
    // -----
    
    self.tableView.contentInset = UIEdgeInsetsMake(44.f, 0.f, 44.f, 0.f);
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _titlesArray.count;
}

#pragma mark - UITableView Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    NSString *rowTitle = self.titlesArray[row];
    NSString *displayName = [AppState sharedInstance].displayName;
    
    SideMenuViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    cell.textLabel.text = rowTitle;
    
    if ([rowTitle isEqualToString:@""]) {
        cell.userInteractionEnabled = NO;
        cell.separatorView.hidden = YES;
    }
    
    if ([rowTitle isEqualToString:displayName] || [rowTitle isEqualToString:@"Log Out"]) {
        cell.separatorView.hidden = YES;
    }

    cell.tintColor = _tintColor;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    NSString *rowTitle = self.titlesArray[row];
    NSString *displayName = [AppState sharedInstance].displayName;
    
    if ([rowTitle isEqualToString:displayName]) {
        [[self sideMenuController] hideLeftViewAnimated:YES completionHandler:nil];
    } else if ([rowTitle isEqualToString:@""]) {
        // Empty
    } else if ([rowTitle isEqualToString:@"Timesheets"]) {
        UINavigationController *presentedNavigationController = (UINavigationController *)[self sideMenuController].rootViewController;
        
        // If the presented controller is different from selection
        if (![presentedNavigationController.childViewControllers[0] isKindOfClass:[TimesheetsViewController class]]) {
            UINavigationController *timesheetsNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:kTimesheetsNavigationController];
            [self sideMenuController].rootViewController = timesheetsNavigationController;
        }
        
        [[self sideMenuController] hideLeftViewAnimated:YES completionHandler:nil];
    } else if ([rowTitle isEqualToString:@"Projects"]) {
        UINavigationController *presentedNavigationController = (UINavigationController *)[self sideMenuController].rootViewController;
        
        // If the presented controller is different from selection
        if (![presentedNavigationController.childViewControllers[0] isKindOfClass:[ProjectsTableViewController class]]) {
            UINavigationController *projectsNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:kProjectsNavigationController];
            [self sideMenuController].rootViewController = projectsNavigationController;
        }
        
        [[self sideMenuController] hideLeftViewAnimated:YES completionHandler:nil];
    } else if ([rowTitle isEqualToString:@"Users"]) {
        UINavigationController *presentedNavigationController = (UINavigationController *)[self sideMenuController].rootViewController;
        
        // If the presented controller is different from selection
        if (![presentedNavigationController.childViewControllers[0] isKindOfClass:[UsersTableViewController class]]) {
            UINavigationController *usersNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:kUsersNavigationController];
            [self sideMenuController].rootViewController = usersNavigationController;
        }
        
        [[self sideMenuController] hideLeftViewAnimated:YES completionHandler:nil];
    } else if ([rowTitle isEqualToString:@"Log Out"]) {
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
