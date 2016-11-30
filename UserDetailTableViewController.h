//
//  UserDetailTableViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/29/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

typedef NS_ENUM (NSInteger, ControllerMode) {
    ControllerMode_Employee,
    ControllerMode_Manager
};

@interface UserDetailTableViewController : UITableViewController

@property (nonatomic, assign) ControllerMode mode;

@end
