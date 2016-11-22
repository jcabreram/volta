//
//  LoginViewController.m
//  Volta
//
//  Created by Jonathan Cabrera on 11/8/16.
//  Copyright © 2016 Ksquare Solutions, Inc. All rights reserved.
//

#import "LoginViewController.h"
#import "AppState.h"
#import "Constants.h"
#import "MainViewController.h"
#import "GlobalVars.h"


@import Firebase;

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end

@implementation LoginViewController

#pragma mark - UIViewController Overrides

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add a background gradient to the view
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    UIColor *lightBlue = [[UIColor alloc] initWithRed:140.0f/255.0f green:211.0f/255.0f blue:255.0f/255.0f alpha:1.0];
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[lightBlue CGColor], nil];
    [self.view.layer insertSublayer:gradient atIndex:0];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Auto-login if already logged in
    FIRUser *user = [FIRAuth auth].currentUser;
    if (user) {
        [self signedIn:user];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self loadCurrentUserToTextField];
}

#pragma mark - IB Actions

- (IBAction)didTapSignIn:(id)sender {
    // Sign In with credentials.
    NSString *email = _emailField.text;
    NSString *password = _passwordField.text;
    
    __weak LoginViewController *welf = self;
    
    [[FIRAuth auth] signInWithEmail:email
                           password:password
                         completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                             if (welf != nil) {
                                 __strong LoginViewController *innerSelf = welf;
                                 
                                 if (error != nil) {
                                     [innerSelf presentLoginErrorAlert:error.localizedDescription];
                                     return;
                                 }
                                 
                                 [innerSelf signedIn:user];
                             }
                         }];
    
    [GlobalVars sharedInstance].completeUsername = email;
}

- (IBAction)didTapSignUp:(id)sender {
    NSString *email = _emailField.text;
    NSString *password = _passwordField.text;
    
    __weak LoginViewController *welf = self;
    
    [[FIRAuth auth] createUserWithEmail:email
                               password:password
                             completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                                 if (welf != nil) {
                                     __strong LoginViewController *innerSelf = welf;
                                     
                                     if (error != nil) {
                                         [innerSelf presentLoginErrorAlert:error.localizedDescription];
                                         return;
                                     }
                                     
                                     [innerSelf setDisplayName:user];
                                 }
                             }];
}

- (IBAction)didRequestPasswordReset:(id)sender {
    
    UIAlertController *prompt;
    prompt = [UIAlertController alertControllerWithTitle:nil
                                                 message:@"Email:"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    NSString *_Nonnull userInput = (prompt.textFields[0].text == nil) ? @"" : prompt.textFields[0].text;
    __weak LoginViewController *welf = self;
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * _Nonnull action) {
                                   if (0 < userInput.length)
                                   {
                                       return;
                                   }
                                   
                                   [[FIRAuth auth] sendPasswordResetWithEmail:userInput
                                                                   completion:^(NSError * _Nullable error) {
                                                                       if (error != nil && welf != nil) {
                                                                           [welf presentLoginErrorAlert:error.localizedDescription];
                                                                       }
                                                                   }];
                                   
                               }];
    [prompt addTextFieldWithConfigurationHandler:nil];
    [prompt addAction:okAction];
    [self presentViewController:prompt animated:YES completion:nil];
}

- (IBAction)dismissKeyboard:(id)sender {
    [self.view endEditing:YES];
}

- (IBAction)loggedOutUsingSegue:(UIStoryboardSegue *)segue
{
    self.emailField.text = @"";
    self.passwordField.text = @"";
}

#pragma mark - Helper Methods

- (void)setDisplayName:(FIRUser *)user {
    FIRUserProfileChangeRequest *changeRequest =
    [user profileChangeRequest];
    // Use first part of email as the default display name
    changeRequest.displayName = [[user.email componentsSeparatedByString:@"@"] objectAtIndex:0];
    [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
        [self signedIn:[FIRAuth auth].currentUser];
    }];
}

- (void)signedIn:(FIRUser *)user {
    
    [AppState sharedInstance].displayName = user.displayName.length > 0 ? user.displayName : user.email;
    [AppState sharedInstance].photoURL = user.photoURL;
    [AppState sharedInstance].signedIn = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationKeysSignedIn
                                                        object:nil userInfo:nil];
    [self performSegueWithIdentifier:SeguesSignInToMainScreen sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *timesheetsNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:kTimesheetsNavigationController];
    MainViewController *mainViewController = segue.destinationViewController;
    [mainViewController setupWithPresentationStyle:LGSideMenuPresentationStyleSlideBelow type:0];
    mainViewController.rootViewController = timesheetsNavigationController;
}

- (void)presentLoginErrorAlert:(NSString *)errorMessage {
    NSLog(@"Presenting Login Error Alert with message:\n%@", errorMessage);
    
    UIAlertController *alert;
    alert = [UIAlertController alertControllerWithTitle:@"Login Error"
                                                message:errorMessage
                                         preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction;
    defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                             style:UIAlertActionStyleDefault
                                           handler:nil];
    
    [alert addAction:defaultAction];
    
    __weak LoginViewController *welf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (welf != nil)
            [welf presentViewController:alert animated:YES completion:nil];
    });
    
    
}

- (void)loadCurrentUserToTextField {
    NSString *savedUser = [GlobalVars sharedInstance].completeUsername;

    if (savedUser != nil && [savedUser length] > 0) {
        self.emailField.text = savedUser;
        [self.passwordField becomeFirstResponder];
    } else {
        [self.emailField becomeFirstResponder];
    }
}

@end
