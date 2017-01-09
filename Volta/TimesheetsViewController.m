//
//  TimesheetsViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/10/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "TimesheetsViewController.h"
#import "Constants.h"
#import "WeeksCollectionViewController.h"
#import "DaysTableViewController.h"

@interface TimesheetsViewController ()

@property (nonatomic, strong) WeeksCollectionViewController *weeksVC;
@property (nonatomic, strong) DaysTableViewController *daysVC;

@property (weak, nonatomic) IBOutlet UILabel *allocatedHoursLabel;

@end

@implementation TimesheetsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueName = segue.identifier;
    
    if ([segueName isEqualToString:SeguesPresentWeeks]) {
        self.weeksVC = (WeeksCollectionViewController *)segue.destinationViewController;
    } else if ([segueName isEqualToString:SeguesPresentDays]) {
        self.daysVC = (DaysTableViewController *)segue.destinationViewController;
    }
    
    self.weeksVC.delegate = self.daysVC;
    self.daysVC.delegate = self;
}

#pragma mark - Days table view delegate

- (void)updateAllocatedHoursWithNumber:(NSNumber *)allocatedHours
{
    self.allocatedHoursLabel.text = [allocatedHours stringValue];
}

@end
