//
//  DaysTableViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/15/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "WeeksCollectionViewController.h"

@interface DaysTableViewController : UITableViewController <WeeksCollectionViewControllerDelegate>

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, assign) NSInteger weekNumber;

@end
