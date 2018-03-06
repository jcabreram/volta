//
//  ProjectsTableViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/22/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//

#import "ProjectDetailTableViewController.h"

@interface ProjectsTableViewController : UITableViewController <ProjectDetailTableViewControllerDelegate>

- (void)resetPresentingController;

@end
