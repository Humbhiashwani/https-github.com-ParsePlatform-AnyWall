//
//  PAWPost.h
//  Anywall
//
//  Copyright (c) 2014 Parse Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>

@interface PAWPost : NSObject <MKAnnotation>

//@protocol MKAnnotation <NSObject>

// Center latitude and longitude of the annotion view.
// The implementation of this property must be KVO compliant.
@property (nonatomic, assign, readonly) CLLocationCoordinate2D coordinate;

// @optional
// Title and subtitle for use by selection UI.
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *subtitle;
// @end

// Other properties:
@property (nonatomic, strong, readonly) PFObject *object;
@property (nonatomic, strong, readonly) PFUser *user;
@property (nonatomic, assign) BOOL animatesDrop;
@property (nonatomic, assign, readonly) MKPinAnnotationColor pinColor;

// Designated initializer.
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                          andTitle:(NSString *)title
                       andSubtitle:(NSString *)subtitle;
- (instancetype)initWithPFObject:(PFObject *)object;


- (void)setTitleAndSubtitleOutsideDistance:(BOOL)outside;

@end
