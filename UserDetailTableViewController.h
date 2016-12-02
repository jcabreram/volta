//
//  UserDetailTableViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/29/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

@class User;

@interface UserDetailTableViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong) User *user;

@end
