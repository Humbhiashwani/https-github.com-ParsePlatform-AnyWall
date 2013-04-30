//
//  PAWSettingsViewController.h
//  Anywall
//
//  Created by Christopher Bowns on 1/30/12.
//

#import <UIKit/UIKit.h>

@interface PAWSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end
