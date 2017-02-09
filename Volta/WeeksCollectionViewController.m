//
//  WeeksCollectionViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/15/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "WeeksCollectionViewController.h"
#import "WeekCollectionViewCell.h"
#import "Constants.h"
#import "DaysTableViewController.h"
#import "AppState.h"
#import "TimesheetWeek.h"
#import "UIColor+VOLcolors.h"
#import "NSDate+VOLDate.h"

@interface WeeksCollectionViewController ()

// Calendar properties
@property (nonatomic, assign) NSInteger currentWeekOfYear;
@property (nonatomic, assign) NSInteger currentYear;
@property (nonatomic, assign) NSInteger lastWeekOfLastYear;

// Collection View properties
@property (nonatomic, assign) BOOL collectionViewScrolled;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

// Firebase properties
@property (nonatomic, strong) FIRDatabaseReference *databaseRef;
@property (nonatomic, assign) FIRDatabaseHandle newWeekHandle;
@property (nonatomic, assign) FIRDatabaseHandle modifiedWeekHandle;
@property (nonatomic, strong) NSMutableDictionary *timesheet;

@end

@implementation WeeksCollectionViewController

static NSString * const reuseIdentifier = @"WeekCell";

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    flow.itemSize = CGSizeMake(170, 58);
    flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flow.minimumInteritemSpacing = 0;
    flow.minimumLineSpacing = 0;
    self.collectionView.collectionViewLayout = flow;
    
    // Boolean for scrolled collection view
    self.collectionViewScrolled = NO;
    
    // Current week of the year
    NSDate *today = [NSDate date];
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    cal.firstWeekday = 2; // Monday
    
    NSDateComponents *currentDateComponents = [cal components:(NSCalendarUnitWeekOfYear | NSCalendarUnitYearForWeekOfYear) fromDate:today];
    self.currentWeekOfYear = [currentDateComponents weekOfYear];
    self.currentYear = [currentDateComponents yearForWeekOfYear];
    
    // Last week of last year
    NSInteger lastDay = 31;
    do {
        NSDateComponents *lastNewYearsEveComponents = [[NSDateComponents alloc] init];
        [lastNewYearsEveComponents setDay:lastDay];
        [lastNewYearsEveComponents setMonth:12];
        [lastNewYearsEveComponents setYearForWeekOfYear:self.currentYear - 1];
        NSDate *lastNewYearsEve = [cal dateFromComponents:lastNewYearsEveComponents];
        self.lastWeekOfLastYear = [cal component:NSCalendarUnitWeekOfYear fromDate:lastNewYearsEve];
        
        lastDay--;
    } while (self.lastWeekOfLastYear == 1);
    
    self.timesheet = [[NSMutableDictionary alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeTimesheet:) name:NotificationKeysTimesheetDidChange object:nil];
    
    [self configureDatabase];
}

- (void)viewDidLayoutSubviews
{
    if (!self.collectionViewScrolled) {
        NSIndexPath *indexPathForToday = [NSIndexPath indexPathForItem:kNumberOfWeeksInPicker-2 inSection:0];
        [self.collectionView selectItemAtIndexPath:indexPathForToday animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPathForToday];
        self.collectionViewScrolled = YES;
    }
}

#pragma mark - Database

- (void)configureDatabase {
    self.databaseRef = [[FIRDatabase database] reference];
    
    NSString *timesheetKey = [AppState sharedInstance].timesheetKey;
    
    // Listen for new weeks added
    self.newWeekHandle = [[[_databaseRef child:@"timesheets"] child:timesheetKey] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
            self.timesheet[snapshot.key] = snapshot.value;
        
            [self.collectionView reloadData];
        } else if ([snapshot.value isKindOfClass:[NSArray class]]) {
            NSArray *weeks = snapshot.value;
            NSMutableDictionary *weeksDictionary = [[NSMutableDictionary alloc] init];
            for (NSInteger i = 0; i < weeks.count; i++) {
                if ([weeks[i] isKindOfClass:[NSNumber class]]) {
                    weeksDictionary[[@(i) stringValue]] = weeks[i];
                }
            }
            self.timesheet[snapshot.key] = [weeksDictionary copy];
            [self.collectionView reloadData];
        }
        
        WeekCollectionViewCell *cell = [self collectionView:self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
        [self.delegate weekStatusChangedTo:cell.week.status];
        [self.actionSheetDelegate weekStatusChangedTo:cell.week.status];
    }];
    
    // Listen for modified weeks
    self.modifiedWeekHandle = [[[_databaseRef child:@"timesheets"] child:timesheetKey] observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
            self.timesheet[snapshot.key] = snapshot.value;
            
            [self.collectionView reloadData];
        } else if ([snapshot.value isKindOfClass:[NSArray class]]) {
            NSArray *weeks = snapshot.value;
            NSMutableDictionary *weeksDictionary = [[NSMutableDictionary alloc] init];
            for (NSInteger i = 0; i < weeks.count; i++) {
                if ([weeks[i] isKindOfClass:[NSNumber class]]) {
                    weeksDictionary[[@(i) stringValue]] = weeks[i];
                }
            }
            self.timesheet[snapshot.key] = [weeksDictionary copy];
            [self.collectionView reloadData];
        }
        
        WeekCollectionViewCell *cell = [self collectionView:self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
        [self.delegate weekStatusChangedTo:cell.week.status];
        [self.actionSheetDelegate weekStatusChangedTo:cell.week.status];
    }];
}

- (void)dealloc {
    NSString *timesheetKey = [AppState sharedInstance].timesheetKey;
    
    [[[self.databaseRef child:@"timesheets"] child:timesheetKey] removeObserverWithHandle:self.newWeekHandle];
    
    [[[self.databaseRef child:@"timesheets"] child:timesheetKey] removeObserverWithHandle:self.modifiedWeekHandle];
}

#pragma mark - Helper Methods

- (void)animateTransitionForView:(UIView *)view toHidden:(BOOL)hidden
{
    [UIView transitionWithView:view
                      duration:0.8
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        view.hidden = hidden;
                    } completion:NULL];
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return kNumberOfWeeksInPicker;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WeekCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (indexPath.item == self.selectedIndexPath.item) {
        [self animateTransitionForView:cell.selectedIndicatorView toHidden:NO];
    } else {
        cell.selectedIndicatorView.hidden = YES;
    }
    
    NSInteger indexFromRightToLeft = kNumberOfWeeksInPicker - indexPath.item - 1;
    NSInteger weekOfYear = self.currentWeekOfYear - indexFromRightToLeft;
    NSInteger year = self.currentYear;
    
    if (weekOfYear < 1) {
        weekOfYear = self.lastWeekOfLastYear + weekOfYear + 1;
        year = self.currentYear - 1;
    }
    
    cell.weekOfYear = weekOfYear;
    cell.year = year;
    
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    
    // Start of the week
    NSDateComponents *comp = [[NSDateComponents alloc] init];
    comp.weekday = 2; // Monday
    comp.weekOfYear = weekOfYear;
    comp.yearForWeekOfYear = year;
    NSDate *startOfWeek = [cal dateFromComponents:comp];
    
    cell.startDate = startOfWeek;
    
    // Add 6 days for end of the week
    NSDate *endOfWeek = [cal dateByAddingUnit:NSCalendarUnitDay value:6 toDate:startOfWeek options:0];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd"];
    
    NSString *startDateString = [dateFormatter stringFromDate:startOfWeek];
    NSString *endDateString = [dateFormatter stringFromDate:endOfWeek];

    NSString *dateRangeString = [NSString stringWithFormat:@"%@ - %@", startDateString, endDateString];
    cell.dateRangeLabel.text = dateRangeString;
    
    // Retrieve status from database and create TimesheetWeek object
    NSString *yearString = [@(year) stringValue];
    NSString *weekOfYearString = [@(weekOfYear) stringValue];
    
    Status weekStatus = Status_NotSubmitted;
    
    // Change background color depending on status
    if (self.timesheet[yearString][weekOfYearString] && [self.timesheet[yearString][weekOfYearString] isKindOfClass:[NSNumber class]]) {
        weekStatus = [self.timesheet[yearString][weekOfYearString] integerValue];
        
        switch (weekStatus) {
            case Status_NotSubmitted:
                cell.statusLabel.text = @"not submitted";
                cell.statusLabel.textColor = [UIColor notSubmittedPastStatusColor];
                cell.dotStatusLabel.textColor = [UIColor notSubmittedPastStatusColor];
                break;
            case Status_Submitted:
                cell.statusLabel.text = @"submitted";
                cell.statusLabel.textColor = [UIColor submittedStatusColor];
                cell.dotStatusLabel.textColor = [UIColor submittedStatusColor];
                break;
            case Status_Approved:
                cell.statusLabel.text = @"approved";
                cell.statusLabel.textColor = [UIColor approvedStatusColor];
                cell.dotStatusLabel.textColor = [UIColor approvedStatusColor];
                break;
            case Status_NotApproved:
                cell.statusLabel.text = @"not approved";
                cell.statusLabel.textColor = [UIColor notApprovedStatusColor];
                cell.dotStatusLabel.textColor = [UIColor notApprovedStatusColor];
                break;
            default:
                break;
        }
    } else {
        cell.statusLabel.text = @"not submitted";
        cell.statusLabel.textColor = [UIColor notSubmittedPastStatusColor];
        cell.dotStatusLabel.textColor = [UIColor notSubmittedPastStatusColor];
    }
    
    BOOL thisWeek = [[NSDate date] isBetweenDate:startOfWeek andDate:endOfWeek];
    BOOL nextWeek = [startOfWeek isAfterDate:[NSDate date]];
    
    if ((thisWeek || nextWeek) && weekStatus == Status_NotSubmitted) {
        cell.statusLabel.textColor = [UIColor notSubmittedStatusColor];
        cell.dotStatusLabel.textColor = [UIColor notSubmittedStatusColor];
    }
    
    if (thisWeek) {
        UIFont *boldFont = [UIFont systemFontOfSize:19.0 weight:UIFontWeightSemibold];
        cell.dateRangeLabel.attributedText = [[NSAttributedString alloc]
                                              initWithString:dateRangeString
                                              attributes:@{
                                                           NSFontAttributeName : boldFont,
                                                           NSForegroundColorAttributeName : [UIColor blackColor]
                                                           }];
    }
    
    TimesheetWeek *week = [[TimesheetWeek alloc] initWithWeekNumber:weekOfYear year:year status:weekStatus];
    cell.week = week;
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndexPath = indexPath;
    [self.collectionView reloadData];
    
    WeekCollectionViewCell *cell = [self collectionView:self.collectionView cellForItemAtIndexPath:indexPath];

    [self.delegate updateWeekViewWithStartDate:cell.startDate forWeek:cell.week];
    [self.actionSheetDelegate chosenWeekChangedToWeek:cell.week];
}

#pragma mark - NSNotificationCenter Observer methods

- (void)didChangeTimesheet:(NSNotification *)notification
{
    self.timesheet = [[NSMutableDictionary alloc] init];
    [self configureDatabase];
    [self.collectionView reloadData];
    
    WeekCollectionViewCell *cell = [self collectionView:self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
    [self.delegate updateWeekViewWithStartDate:cell.startDate forWeek:cell.week];
    [self.actionSheetDelegate chosenWeekChangedToWeek:cell.week];
}

@end
