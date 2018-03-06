//
//  UserDetailCell.h
//  Volta
//
//  Created by Jonathan Cabrera on 12/2/16.
//  Copyright © 2016 Jonathan Cabrera. All rights reserved.
//

@class MLPAutoCompleteTextField;

@interface UserDetailCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet MLPAutoCompleteTextField *companyTextField;
@property (weak, nonatomic) IBOutlet MLPAutoCompleteTextField *managerTextField;
@property (weak, nonatomic) IBOutlet MLPAutoCompleteTextField *projectTextField;
@property (weak, nonatomic) IBOutlet UISwitch *requiresPhotoSwitch;

@end
