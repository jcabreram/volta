//
//  UserDetailTableViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/29/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

@class User;

typedef NS_ENUM (NSInteger, ControllerMode) {
    ControllerMode_Employee,
    ControllerMode_Manager,
    ControllerMode_Admin,
    ControllerMode_Edit
};

@interface UserDetailTableViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, assign) ControllerMode mode;
@property (nonatomic, strong) User *user;

@end
