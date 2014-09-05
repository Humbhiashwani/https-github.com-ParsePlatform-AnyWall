//
//  PAWWallViewController.m
//  Anywall
//
//  Copyright (c) 2014 Parse Inc. All rights reserved.
//

#import "PAWWallViewController.h"

#import "PAWConstants.h"
#import "PAWPost.h"
#import "PAWWallPostCreateViewController.h"
#import "PAWWallPostsTableViewController.h"

@interface PAWWallViewController ()
<PAWWallPostsTableViewControllerDataSource,
PAWWallPostCreateViewControllerDataSource>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;

@property (nonatomic, strong) MKCircle *circleOverlay;
@property (nonatomic, strong) NSMutableArray *annotations;
@property (nonatomic, assign) BOOL mapPinsPlaced;
@property (nonatomic, assign) BOOL mapPannedSinceLocationUpdate;

@property (nonatomic, strong) PAWWallPostsTableViewController *wallPostsTableViewController;

@property (nonatomic, strong) NSMutableArray *allPosts;

@end

@implementation PAWWallViewController

#pragma mark -
#pragma mark Init

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Anywall";

        _annotations = [[NSMutableArray alloc] initWithCapacity:10];
        _allPosts = [[NSMutableArray alloc] initWithCapacity:10];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(distanceFilterDidChange:)
                                                     name:PAWFilterDistanceDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(postWasCreated:)
                                                     name:PAWPostCreatedNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    [_locationManager stopUpdatingLocation];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAWFilterDistanceDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAWPostCreatedNotification object:nil];
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [self loadWallPostsTableViewController];

    // Set our nav bar items.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Post"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(postButtonSelected:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(settingsButtonSelected:)];

    self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(37.332495f, -122.029095f),
                                                 MKCoordinateSpanMake(0.008516f, 0.021801f));
    self.mapPannedSinceLocationUpdate = NO;
    [self startStandardUpdates];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:animated];

    [self.locationManager startUpdatingLocation];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self.locationManager stopUpdatingLocation];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    const CGRect bounds = self.view.bounds;

    CGRect tableViewFrame = CGRectZero;
    tableViewFrame.origin.x = 6.0f;
    tableViewFrame.origin.y = CGRectGetMaxY(self.mapView.frame) + 6.0f;
    tableViewFrame.size.width = CGRectGetMaxX(bounds) - CGRectGetMinX(tableViewFrame) * 2.0f;
    tableViewFrame.size.height = CGRectGetMaxY(bounds) - CGRectGetMaxY(tableViewFrame);
    self.wallPostsTableViewController.view.frame = tableViewFrame;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

#pragma mark -
#pragma mark WallPostsTableViewController

- (void)loadWallPostsTableViewController {
    // Add the wall posts tableview as a subview with view containment (new in iOS 5.0):
    self.wallPostsTableViewController = [[PAWWallPostsTableViewController alloc] initWithStyle:UITableViewStylePlain];
    self.wallPostsTableViewController.dataSource = self;
    [self.view addSubview:self.wallPostsTableViewController.view];
    [self addChildViewController:self.wallPostsTableViewController];
    [self.wallPostsTableViewController didMoveToParentViewController:self];
}

#pragma mark DataSource

- (CLLocation *)currentLocationForWallPostsTableViewController:(PAWWallPostsTableViewController *)controller {
    return self.currentLocation;
}

#pragma mark -
#pragma mark WallPostCreatViewController

- (void)presentWallPostCreateViewController {
    PAWWallPostCreateViewController *viewController = [[PAWWallPostCreateViewController alloc] initWithNibName:nil bundle:nil];
    viewController.dataSource = self;
    [self.navigationController presentViewController:viewController animated:YES completion:nil];
}

#pragma mark DataSource

- (CLLocation *)currentLocationForWallPostCrateViewController:(PAWWallPostCreateViewController *)controller {
    return self.currentLocation;
}

#pragma mark -
#pragma mark NSNotificationCenter notification handlers

- (void)distanceFilterDidChange:(NSNotification *)note {
    CLLocationAccuracy filterDistance = [[note userInfo][kPAWFilterDistanceKey] doubleValue];

    if (self.circleOverlay != nil) {
        [self.mapView removeOverlay:self.circleOverlay];
        self.circleOverlay = nil;
    }
    self.circleOverlay = [MKCircle circleWithCenterCoordinate:self.currentLocation.coordinate radius:filterDistance];
    [self.mapView addOverlay:self.circleOverlay];

    // Update our pins for the new filter distance:
    [self updatePostsForLocation:self.currentLocation withNearbyDistance:filterDistance];

    // If they panned the map since our last location update, don't recenter it.
    if (!self.mapPannedSinceLocationUpdate) {
        // Set the map's region centered on their location at 2x filterDistance
        MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(self.currentLocation.coordinate, filterDistance * 2.0f, filterDistance * 2.0f);

        [self.mapView setRegion:newRegion animated:YES];
        self.mapPannedSinceLocationUpdate = NO;
    } else {
        // Just zoom to the new search radius (or maybe don't even do that?)
        MKCoordinateRegion currentRegion = self.mapView.region;
        MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(currentRegion.center, filterDistance * 2.0f, filterDistance * 2.0f);

        BOOL oldMapPannedValue = self.mapPannedSinceLocationUpdate;
        [self.mapView setRegion:newRegion animated:YES];
        self.mapPannedSinceLocationUpdate = oldMapPannedValue;
    }
}

- (void)setCurrentLocation:(CLLocation *)currentLocation {
    if (self.currentLocation == currentLocation) {
        return;
    }

    _currentLocation = currentLocation;

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PAWCurrentLocationDidChangeNotification
                                                            object:nil
                                                          userInfo:@{ kPAWLocationKey : currentLocation } ];
    });
    
    CLLocationAccuracy filterDistance = [[NSUserDefaults standardUserDefaults] doubleForKey:PAWUserDefaultsFilterDistanceKey];

    // If they panned the map since our last location update, don't recenter it.
    if (!self.mapPannedSinceLocationUpdate) {
        // Set the map's region centered on their new location at 2x filterDistance
        MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(self.currentLocation.coordinate, filterDistance * 2.0f, filterDistance * 2.0f);

        BOOL oldMapPannedValue = self.mapPannedSinceLocationUpdate;
        [self.mapView setRegion:newRegion animated:YES];
        self.mapPannedSinceLocationUpdate = oldMapPannedValue;
    } // else do nothing.

    if (self.circleOverlay != nil) {
        [self.mapView removeOverlay:self.circleOverlay];
        self.circleOverlay = nil;
    }
    self.circleOverlay = [MKCircle circleWithCenterCoordinate:self.currentLocation.coordinate radius:filterDistance];
    [self.mapView addOverlay:self.circleOverlay];

    // Update the map with new pins:
    [self queryForAllPostsNearLocation:self.currentLocation withNearbyDistance:filterDistance];
    // And update the existing pins to reflect any changes in filter distance:
    [self updatePostsForLocation:self.currentLocation withNearbyDistance:filterDistance];
}

- (void)postWasCreated:(NSNotification *)note {
    CLLocationAccuracy filterDistance = [[NSUserDefaults standardUserDefaults] doubleForKey:PAWUserDefaultsFilterDistanceKey];
    [self queryForAllPostsNearLocation:self.currentLocation withNearbyDistance:filterDistance];
}

#pragma mark -
#pragma mark UINavigationBar-based actions

- (IBAction)settingsButtonSelected:(id)sender {
    [self.delegate wallViewControllerWantsToPresentSettings:self];
}

- (IBAction)postButtonSelected:(id)sender {
    [self presentWallPostCreateViewController];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate methods and helpers

- (CLLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];

        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;

        // Set a movement threshold for new events.
        _locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
    }
    return _locationManager;
}

- (void)startStandardUpdates {
    [self.locationManager startUpdatingLocation];

    CLLocation *currentLocation = self.locationManager.location;
    if (currentLocation) {
        self.currentLocation = currentLocation;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    switch (status) {
        case kCLAuthorizationStatusAuthorized:
        {
            NSLog(@"kCLAuthorizationStatusAuthorized");
            // Re-enable the post button if it was disabled before.
            self.navigationItem.rightBarButtonItem.enabled = YES;
            [self.locationManager startUpdatingLocation];
        }
            break;
        case kCLAuthorizationStatusDenied:
            NSLog(@"kCLAuthorizationStatusDenied");
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Anywall can’t access your current location.\n\nTo view nearby posts or create a post at your current location, turn on access for Anywall to your location in the Settings app under Location Services." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            // Disable the post button.
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
            break;
        case kCLAuthorizationStatusNotDetermined:
        {
            NSLog(@"kCLAuthorizationStatusNotDetermined");
        }
            break;
        case kCLAuthorizationStatusRestricted:
        {
            NSLog(@"kCLAuthorizationStatusRestricted");
        }
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.currentLocation = newLocation;
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"Error: %@", [error description]);

    if (error.code == kCLErrorDenied) {
        [self.locationManager stopUpdatingLocation];
    } else if (error.code == kCLErrorLocationUnknown) {
        // todo: retry?
        // set a timer for five seconds to cycle location, and if it fails again, bail and tell the user.
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay {
    if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleRenderer *circleRenderer = [[MKCircleRenderer alloc] initWithCircle:self.circleOverlay];
        [circleRenderer setFillColor:[[UIColor darkGrayColor] colorWithAlphaComponent:0.2f]];
        [circleRenderer setStrokeColor:[[UIColor darkGrayColor] colorWithAlphaComponent:0.7f]];
        [circleRenderer setLineWidth:1.0f];
        return circleRenderer;
    }
    return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapVIew viewForAnnotation:(id<MKAnnotation>)annotation {
    // Let the system handle user location annotations.
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }

    static NSString *pinIdentifier = @"CustomPinAnnotation";

    // Handle any custom annotations.
    if ([annotation isKindOfClass:[PAWPost class]]) {
        // Try to dequeue an existing pin view first.
        MKPinAnnotationView *pinView = (MKPinAnnotationView*)[mapVIew dequeueReusableAnnotationViewWithIdentifier:pinIdentifier];

        if (!pinView) {
            // If an existing pin view was not available, create one.
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:pinIdentifier];
        } else {
            pinView.annotation = annotation;
        }
        pinView.pinColor = [(PAWPost *)annotation pinColor];
        pinView.animatesDrop = [((PAWPost *)annotation) animatesDrop];
        pinView.canShowCallout = YES;

        return pinView;
    }

    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    id<MKAnnotation> annotation = [view annotation];
    if ([annotation isKindOfClass:[PAWPost class]]) {
        PAWPost *post = [view annotation];
        [self.wallPostsTableViewController highlightCellForPost:post];
    } else if ([annotation isKindOfClass:[MKUserLocation class]]) {
        // Center the map on the user's current location:
        CLLocationAccuracy filterDistance = [[NSUserDefaults standardUserDefaults] doubleForKey:PAWUserDefaultsFilterDistanceKey];
        MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(self.currentLocation.coordinate,
                                                                          filterDistance * 2.0f,
                                                                          filterDistance * 2.0f);

        [self.mapView setRegion:newRegion animated:YES];
        self.mapPannedSinceLocationUpdate = NO;
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    id<MKAnnotation> annotation = [view annotation];
    if ([annotation isKindOfClass:[PAWPost class]]) {
        PAWPost *post = [view annotation];
        [self.wallPostsTableViewController unhighlightCellForPost:post];
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    self.mapPannedSinceLocationUpdate = YES;
}

#pragma mark -
#pragma mark Fetch map pins

- (void)queryForAllPostsNearLocation:(CLLocation *)currentLocation withNearbyDistance:(CLLocationAccuracy)nearbyDistance {
    PFQuery *query = [PFQuery queryWithClassName:PAWParsePostsClassName];

    if (currentLocation == nil) {
        NSLog(@"%s got a nil location!", __PRETTY_FUNCTION__);
    }

    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.allPosts count] == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }

    // Query for posts sort of kind of near our current location.
    PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
    [query whereKey:PAWParsePostLocationKey nearGeoPoint:point withinKilometers:PAWWallPostMaximumSearchDistance];
    [query includeKey:PAWParsePostUserKey];
    query.limit = PAWWallPostsSearchDefaultLimit;

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"error in geo query!"); // todo why is this ever happening?
        } else {
            // We need to make new post objects from objects,
            // and update allPosts and the map to reflect this new array.
            // But we don't want to remove all annotations from the mapview blindly,
            // so let's do some work to figure out what's new and what needs removing.

            // 1. Find genuinely new posts:
            NSMutableArray *newPosts = [[NSMutableArray alloc] initWithCapacity:PAWWallPostsSearchDefaultLimit];
            // (Cache the objects we make for the search in step 2:)
            NSMutableArray *allNewPosts = [[NSMutableArray alloc] initWithCapacity:[objects count]];
            for (PFObject *object in objects) {
                PAWPost *newPost = [[PAWPost alloc] initWithPFObject:object];
                [allNewPosts addObject:newPost];
                if (![_allPosts containsObject:newPost]) {
                    [newPosts addObject:newPost];
                }
            }
            // newPosts now contains our new objects.

            // 2. Find posts in allPosts that didn't make the cut.
            NSMutableArray *postsToRemove = [[NSMutableArray alloc] initWithCapacity:PAWWallPostsSearchDefaultLimit];
            for (PAWPost *currentPost in _allPosts) {
                if (![allNewPosts containsObject:currentPost]) {
                    [postsToRemove addObject:currentPost];
                }
            }
            // postsToRemove has objects that didn't come in with our new results.

            // 3. Configure our new posts; these are about to go onto the map.
            for (PAWPost *newPost in newPosts) {
                CLLocation *objectLocation = [[CLLocation alloc] initWithLatitude:newPost.coordinate.latitude
                                                                        longitude:newPost.coordinate.longitude];
                // if this post is outside the filter distance, don't show the regular callout.
                CLLocationDistance distanceFromCurrent = [currentLocation distanceFromLocation:objectLocation];
                [newPost setTitleAndSubtitleOutsideDistance:( distanceFromCurrent > nearbyDistance ? YES : NO )];
                // Animate all pins after the initial load:
                newPost.animatesDrop = self.mapPinsPlaced;
            }

            // At this point, newAllPosts contains a new list of post objects.
            // We should add everything in newPosts to the map, remove everything in postsToRemove,
            // and add newPosts to allPosts.
            [self.mapView removeAnnotations:postsToRemove];
            [self.mapView addAnnotations:newPosts];

            [_allPosts addObjectsFromArray:newPosts];
            [_allPosts removeObjectsInArray:postsToRemove];

            self.mapPinsPlaced = YES;
        }
    }];
}

// When we update the search filter distance, we need to update our pins' titles to match.
- (void)updatePostsForLocation:(CLLocation *)currentLocation withNearbyDistance:(CLLocationAccuracy) nearbyDistance {
    for (PAWPost *post in _allPosts) {
        CLLocation *objectLocation = [[CLLocation alloc] initWithLatitude:post.coordinate.latitude
                                                                longitude:post.coordinate.longitude];

        // if this post is outside the filter distance, don't show the regular callout.
        CLLocationDistance distanceFromCurrent = [currentLocation distanceFromLocation:objectLocation];
        if (distanceFromCurrent > nearbyDistance) { // Outside search radius
            [post setTitleAndSubtitleOutsideDistance:YES];
            [(MKPinAnnotationView *)[self.mapView viewForAnnotation:post] setPinColor:post.pinColor];
        } else {
            [post setTitleAndSubtitleOutsideDistance:NO]; // Inside search radius
            [(MKPinAnnotationView *)[self.mapView viewForAnnotation:post] setPinColor:post.pinColor];
        }
    }
}

@end
