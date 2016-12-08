//
//  ProjectDetailTableViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 12/6/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

@class Project;

@interface ProjectDetailTableViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong) Project *project;

@end
