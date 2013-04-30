//
//  PAWSearchRadius.h
//  Anywall
//
//  Created by Christopher Bowns on 2/8/12.
//

#import <MapKit/MapKit.h>

@interface PAWSearchRadius : NSObject <MKOverlay>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) CLLocationDistance radius;
@property (nonatomic, assign) MKMapRect boundingMapRect;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate radius:(CLLocationDistance)radius;

@end
