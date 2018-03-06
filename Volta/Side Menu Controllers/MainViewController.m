//
//  MainViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/9/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//

#import "MainViewController.h"
#import "SideMenuViewController.h"
#import "Constants.h"

@interface MainViewController ()

@property (strong, nonatomic) SideMenuViewController *sideMenuViewController;

@end

@implementation MainViewController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    
    if (self) {
        [self setupWithPresentationStyle:LGSideMenuPresentationStyleSlideBelow type:0];
    }
    
    return self;
}

- (void)setupWithPresentationStyle:(LGSideMenuPresentationStyle)style
                              type:(NSUInteger)type
{
    _sideMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:kSideMenuViewController];
    
    [self setLeftViewEnabledWithWidth:200.f
                    presentationStyle:style
                 alwaysVisibleOptions:LGSideMenuAlwaysVisibleOnNone];
    
    self.leftViewStatusBarStyle = UIStatusBarStyleLightContent;
    self.leftViewStatusBarVisibleOptions = LGSideMenuStatusBarVisibleOnAll;
    
    
    self.leftViewBackgroundImage = [UIImage imageNamed:@"gradient-background"];
    
    _sideMenuViewController.tableView.backgroundColor = [UIColor clearColor];
    _sideMenuViewController.tintColor = [UIColor whiteColor];
    
    
    [_sideMenuViewController.tableView reloadData];
    [self.leftView addSubview:_sideMenuViewController.tableView];
}

- (void)leftViewWillLayoutSubviewsWithSize:(CGSize)size
{
    [super leftViewWillLayoutSubviewsWithSize:size];
    
    _sideMenuViewController.tableView.frame = CGRectMake(0.f , 0.f, size.width, size.height);
}

- (void)logout
{
    [self performSegueWithIdentifier:SeguesMainScreenToSignIn sender:self];
}

@end
