//
//  DayDetailTableViewCell.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/22/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

@class MLPAutoCompleteTextField;

@interface DayDetailTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet MLPAutoCompleteTextField *projectField;
@property (weak, nonatomic) IBOutlet UITextField *hoursField;

@end
