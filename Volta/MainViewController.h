//
//  MainViewController.h
//  Volta
//
//  Created by Jonathan Cabrera on 11/9/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LGSideMenuController.h"

@interface MainViewController : LGSideMenuController

- (void)setupWithPresentationStyle:(LGSideMenuPresentationStyle)style
                              type:(NSUInteger)type;

- (void)logout;

@end
