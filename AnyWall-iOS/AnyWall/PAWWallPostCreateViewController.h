//
//  PAWWallPostCreateViewController.h
//  Anywall
//
//  Copyright (c) 2014 Parse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PAWWallPostCreateViewController;

@protocol PAWWallPostCreateViewControllerDataSource <NSObject>

- (CLLocation *)currentLocationForWallPostCrateViewController:(PAWWallPostCreateViewController *)controller;

@end

@interface PAWWallPostCreateViewController : UIViewController

@property (nonatomic, weak) id<PAWWallPostCreateViewControllerDataSource> dataSource;

@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutlet UILabel *characterCountLabel;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *postButton;

- (IBAction)cancelPost:(id)sender;
- (IBAction)postPost:(id)sender;

@end
