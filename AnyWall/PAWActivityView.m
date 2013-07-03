//
//  PAWActivityView.m
//  Anywall
//
//  Created by Christopher Bowns on 2/6/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "PAWActivityView.h"

static CGFloat const kPAWActivityViewActivityIndicatorPadding = 10.f;

@implementation PAWActivityView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		self.label = [[UILabel alloc] initWithFrame:CGRectZero];
		self.label.textColor = [UIColor whiteColor];
		self.label.backgroundColor = [UIColor clearColor];
		self.label.font = [UIFont boldSystemFontOfSize:20.f];

		self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

		self.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.7f];

		[self addSubview:self.label];
		[self addSubview:self.activityIndicator];
		
		[self.activityIndicator startAnimating];
    }
    return self;
}

- (void)setStatus:(NSString *)status {
	_status = status;
	self.label.text = _status;
}

- (void)layoutSubviews {
	// center the label and activity indicator.
	[self.label sizeToFit];
	self.label.center = CGPointMake(self.frame.size.width / 2 + 10.f, self.frame.size.height / 2);
	self.label.frame = CGRectIntegral(self.label.frame);

	self.activityIndicator.center = CGPointMake(self.label.frame.origin.x - (self.activityIndicator.frame.size.width / 2) - kPAWActivityViewActivityIndicatorPadding, self.label.frame.origin.y + (self.label.frame.size.height / 2));
}

@end
