//
//  ProjectDetailCell.h
//  Volta
//
//  Created by Jonathan Cabrera on 12/6/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

@class MLPAutoCompleteTextField;

@interface ProjectDetailCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *defaultDurationField;
@property (weak, nonatomic) IBOutlet UITextField *organizationField;
@property (weak, nonatomic) IBOutlet MLPAutoCompleteTextField *companyField;

@end
