//
//  ProjectDetailTableViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 12/6/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//

@class Project;
#import "MLPAutoCompleteTextField.h"

@protocol ProjectDetailTableViewControllerDelegate <NSObject>

- (void)resetPresentingController;

@end

@interface ProjectDetailTableViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong) Project *project;
@property (nonatomic, weak) id<ProjectDetailTableViewControllerDelegate> delegate;

@end
