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
                     @"Projects"];
    
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
    cell.separatorView.hidden = indexPath.row <= 1 || indexPath.row == _titlesArray.count - 1;
    cell.userInteractionEnabled = indexPath.row != 1;
    cell.tintColor = _tintColor;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == 1 ? 22.f : 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        [[self sideMenuController] hideLeftViewAnimated:YES completionHandler:nil];
    } else if (indexPath.row == 2) { // Row 1 is empty
        UINavigationController *presentedNavigationController = (UINavigationController *)[self sideMenuController].rootViewController;
        
        // If the presented controller is different from selection
        if (![presentedNavigationController.childViewControllers[0] isKindOfClass:[TimesheetsViewController class]]) {
            UINavigationController *timesheetsNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:kTimesheetsNavigationController];
            [self sideMenuController].rootViewController = timesheetsNavigationController;
        }
        
        [[self sideMenuController] hideLeftViewAnimated:YES completionHandler:nil];

    } else {
        UIViewController *viewController = [UIViewController new];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        viewController.view.backgroundColor = [UIColor whiteColor];
        viewController.title = _titlesArray[indexPath.row];
        [self sideMenuController].rootViewController = navigationController;
        
        [[self sideMenuController] hideLeftViewAnimated:YES completionHandler:nil];
    }
}


@end
