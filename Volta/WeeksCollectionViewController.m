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

@interface WeeksCollectionViewController ()

@property (nonatomic, assign) NSInteger currentWeekOfYear;
@property (nonatomic, assign) NSInteger currentYear;
@property (nonatomic, assign) NSInteger lastWeekOfLastYear;

@property (nonatomic, assign) BOOL collectionViewScrolled;
@property (nonatomic, assign) NSInteger selectedItem;

@end

@implementation WeeksCollectionViewController

static NSString * const reuseIdentifier = @"WeekCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
    flow.itemSize = CGSizeMake(75, 80);
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
    
    NSDateComponents *currentDateComponents = [cal components:(NSCalendarUnitWeekOfYear | NSCalendarUnitYear) fromDate:today];
    self.currentWeekOfYear = [currentDateComponents weekOfYear];
    self.currentYear = [currentDateComponents year];
    
    // Last week of last year
    NSDateComponents *lastNewYearsEveComponents = [[NSDateComponents alloc] init];
    [lastNewYearsEveComponents setDay:25];
    [lastNewYearsEveComponents setMonth:12];
    [lastNewYearsEveComponents setYear:self.currentYear - 1];
    NSDate *lastNewYearsEve = [cal dateFromComponents:lastNewYearsEveComponents];
    self.lastWeekOfLastYear = [cal component:NSCalendarUnitWeekOfYear fromDate:lastNewYearsEve];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    //[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    if (indexPath.item == self.selectedItem) {
        cell.layer.borderWidth = 1.0f;
        cell.layer.borderColor = [UIColor darkGrayColor].CGColor;
    } else {
        cell.layer.borderWidth = 0.0f;
        cell.layer.borderColor = [UIColor clearColor].CGColor;
    }
    
    NSInteger indexFromRightToLeft = kNumberOfWeeksInPicker - indexPath.item - 1;
    NSInteger weekOfYear = self.currentWeekOfYear - indexFromRightToLeft + 1; // Adding one to get a week ahead
    NSInteger year = self.currentYear;
    
    if (weekOfYear < 1) {
        weekOfYear = self.lastWeekOfLastYear + weekOfYear;
        year = self.currentYear - 1;
    }
    
    cell.weekOfYear = weekOfYear;
    cell.year = year;
    
    NSCalendar *cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    
    // Start of the week
    NSDateComponents *comp = [[NSDateComponents alloc] init];
    comp.weekday = 2; // Monday
    comp.weekOfYear = weekOfYear;
    comp.year = year;
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
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedItem = indexPath.item;
    [self.collectionView reloadData];
    
    WeekCollectionViewCell *cell = [self collectionView:self.collectionView cellForItemAtIndexPath:indexPath];

    [self.delegate updateWeekViewWithStartDate:cell.startDate forWeekNumber:cell.weekOfYear];
}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
