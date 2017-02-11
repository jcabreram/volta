//
//  UserCell.h
//  Volta
//
//  Created by Jonathan Cabrera on 2/10/17.
//  Copyright © 2017 Ksquare Solutions, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *dotIndicatorLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *companyLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dotIndicatorLabelConstraint;

@end
