//
//  UsersTableViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/29/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//

#import "UserDetailTableViewController.h"

@interface UsersTableViewController : UITableViewController <UserDetailTableViewControllerDelegate>

- (void)resetPresentingController;

@end
