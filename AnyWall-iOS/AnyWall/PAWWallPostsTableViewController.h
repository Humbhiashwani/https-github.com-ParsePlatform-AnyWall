//
//  PAWWallPostsTableViewController.h
//  Anywall
//
//  Copyright (c) 2014 Parse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "PAWWallViewController.h"

@class PAWWallPostsTableViewController;

@protocol PAWWallPostsTableViewControllerDataSource <NSObject>

- (CLLocation *)currentLocationForWallPostsTableViewController:(PAWWallPostsTableViewController *)controller;

@end

@interface PAWWallPostsTableViewController : PFQueryTableViewController <PAWWallViewControllerHighlight>

@property (nonatomic, weak) id<PAWWallPostsTableViewControllerDataSource> dataSource;

@end
