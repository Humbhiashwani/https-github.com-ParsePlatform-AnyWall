//
//  PAWNewUserViewController.h
//  Anywall
//
//  Created by Christopher Bowns on 2/1/12.
//

#import <UIKit/UIKit.h>

@interface PAWNewUserViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;

@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic, strong) IBOutlet UITextField *passwordAgainField;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end
