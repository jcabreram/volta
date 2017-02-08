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
#import "MBProgressHUD.h"

@interface LoginViewController ()
{
    CAGradientLayer *gradient;
}

@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end

@implementation LoginViewController

#pragma mark - UIViewController Overrides

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add a background gradient to the view
    gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    UIColor *lightBlue = [[UIColor alloc] initWithRed:140.0f/255.0f green:211.0f/255.0f blue:255.0f/255.0f alpha:1.0];
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[lightBlue CGColor], nil];
    [self.view.layer insertSublayer:gradient atIndex:0];
    
    // Add an observer for updating background when rotating
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadBackground) name:UIDeviceOrientationDidChangeNotification object:nil];
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

- (void)reloadBackground {
    gradient.frame = self.view.bounds;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark - IB Actions

- (IBAction)didTapSignIn:(id)sender {
    // Sign In with credentials.
    NSString *email = _emailField.text;
    NSString *password = _passwordField.text;
    
    __weak LoginViewController *welf = self;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[FIRAuth auth] signInWithEmail:email
                           password:password
                         completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
                             if (welf != nil) {
                                 [hud hideAnimated:YES];
                                 
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

- (IBAction)didRequestPasswordReset:(id)sender {
    
    UIAlertController *prompt =
    [UIAlertController alertControllerWithTitle:nil
                                        message:@"Enter your email:"
                                 preferredStyle:UIAlertControllerStyleAlert];
    __weak UIAlertController *weakPrompt = prompt;
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * _Nonnull action) {
                                   UIAlertController *strongPrompt = weakPrompt;
                                   NSString *userInput = strongPrompt.textFields[0].text;
                                   if (!userInput.length)
                                   {
                                       return;
                                   }
                                   MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                   
                                   [[FIRAuth auth] sendPasswordResetWithEmail:userInput
                                                                   completion:^(NSError * _Nullable error) {
                                                                       
                                                                       [hud hideAnimated:YES];
                                                                       
                                                                       if (error) {
                                                                           NSLog(@"%@", error.localizedDescription);
                                                                           UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:@"Password Reset Error"
                                                                                                                                                 message:error.localizedDescription
                                                                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                                                                           UIAlertAction *okConfirmation = [UIAlertAction actionWithTitle:@"OK"
                                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                                  handler:nil];
                                                                           [confirmation addAction:okConfirmation];
                                                                           [self presentViewController:confirmation animated:YES completion:nil];
                                                                           return;
                                                                       } else {
                                                                           UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:@"Password Reset Email Sent"
                                                                                                                                                 message:[NSString stringWithFormat:@"An email has been sent to your email address, %@. Follow the directions in the email to reset your password.", userInput]
                                                                                                        preferredStyle:UIAlertControllerStyleAlert];
                                                                           UIAlertAction *okConfirmation = [UIAlertAction actionWithTitle:@"OK"
                                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                                  handler:nil];
                                                                           [confirmation addAction:okConfirmation];
                                                                           [self presentViewController:confirmation animated:YES completion:nil];
                                                                       }
                                                                   }];
                                   
                               }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:nil];
    [prompt addTextFieldWithConfigurationHandler:nil];
    [prompt addAction:okAction];
    [prompt addAction:cancelAction];
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
    
    FIRDatabaseReference *ref = [[FIRDatabase database] reference];
    
    AppState *state = [AppState sharedInstance];
    
    state.userID = user.uid;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[[ref child:@"users"] child:user.uid] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSLog(@"");
        [hud hideAnimated:YES];
        if (snapshot.exists) {
            state.displayName = snapshot.value[@"first_name"];
            [state setTypeWithString:snapshot.value[@"type"]];
            state.timesheetKey = snapshot.value[@"timesheet"];
            state.requiresPhoto = [snapshot.value[@"requires_photo"] boolValue];
            
            state.signedIn = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationKeysSignedIn
                                                                object:nil userInfo:nil];
            
            // We subscribe the user to his topic based notification
            NSString *userTopic = [[NSString alloc] initWithFormat:@"/topics/user_%@", user.uid];
            [[FIRMessaging messaging] subscribeToTopic:userTopic];
            
            NSString *userTypeTopic = [[NSString alloc] initWithFormat:@"/topics/%@", [state stringInPluralWithType]];
            [[FIRMessaging messaging] subscribeToTopic:userTypeTopic];
            
            [self performSegueWithIdentifier:SeguesSignInToMainScreen sender:self];
        } else {
            [self presentLoginErrorAlert:@"The specified user doesn't have an account in Volta."];
            state.signedIn = NO;
        }
        
    }];
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
