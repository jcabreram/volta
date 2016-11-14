//
//  SideMenuViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/9/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "SideMenuViewController.h"
#import "SideMenuViewCell.h"
#import "AppState.h"
#import "UIViewController+LGSideMenuController.h"

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
        if (![[self sideMenuController] isLeftViewAlwaysVisible]) {
            [[self sideMenuController] hideLeftViewAnimated:YES completionHandler:^(void) {
                [[self sideMenuController] showRightViewAnimated:YES completionHandler:nil];
            }];
        } else {
            [[self sideMenuController] showRightViewAnimated:YES completionHandler:nil];
        }
    } else {
        UIViewController *viewController = [UIViewController new];
        viewController.view.backgroundColor = [UIColor whiteColor];
        viewController.title = _titlesArray[indexPath.row];
        [(UINavigationController *)[self sideMenuController].rootViewController pushViewController:viewController animated:YES];
        
        [[self sideMenuController] hideLeftViewAnimated:YES completionHandler:nil];
    }
}


@end
