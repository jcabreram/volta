//
//  UserDetailTableViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/29/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

@class User;
#import "MLPAutoCompleteTextField.h"

@protocol UserDetailTableViewControllerDelegate <NSObject>

- (void)resetPresentingController;

@end

@interface UserDetailTableViewController : UITableViewController <UITextFieldDelegate, MLPAutoCompleteTextFieldDataSource>

@property (nonatomic, strong) User *user;
@property (nonatomic, weak) id<UserDetailTableViewControllerDelegate> delegate;

@end
