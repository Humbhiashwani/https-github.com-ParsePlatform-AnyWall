//
//  PAWLoginViewController.h
//  Anywall
//
//  Created by Christopher Bowns on 2/1/12.
//

#import <UIKit/UIKit.h>

@interface PAWLoginViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;

@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *passwordField;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end
