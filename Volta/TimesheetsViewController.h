//
//  TimesheetsViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/10/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "DaysTableViewController.h"
#import "WeeksCollectionViewController.h"
#import "NDHTMLtoPDF.h"

@interface TimesheetsViewController : UIViewController <DaysTableViewControllerDelegate, WeeksCollectionViewControllerActionSheetDelegate, NDHTMLtoPDFDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) TimesheetWeek *week;
@property (nonatomic, strong) NDHTMLtoPDF *PDFCreator;

- (void)chosenWeekChangedToWeek:(TimesheetWeek *)week;

@end
