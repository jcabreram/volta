//
//  UserDetailTableViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/29/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//

@class User;
@import MessageUI;
#import "MLPAutoCompleteTextField.h"

@protocol UserDetailTableViewControllerDelegate <NSObject>

- (void)resetPresentingController;

@end

@interface UserDetailTableViewController : UITableViewController <UITextFieldDelegate, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) User *user;
@property (nonatomic, weak) id<UserDetailTableViewControllerDelegate> delegate;

@end
