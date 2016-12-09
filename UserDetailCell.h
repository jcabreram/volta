//
//  UserDetailCell.h
//  Volta
//
//  Created by Jonathan Cabrera on 12/2/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

@interface UserDetailCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *companyTextField;
@property (weak, nonatomic) IBOutlet UITextField *managerTextField;

@end
