//
//  PAWPostTableViewCell.h
//  Anywall
//
//  Copyright (c) 2014 Parse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const PAWPostTableViewCellLabelsFontSize;

typedef NS_ENUM(uint8_t, PAWPostTableViewCellStyle)
{
    PAWPostTableViewCellStyleLeft = 1,
    PAWPostTableViewCellStyleRight
};

@class PAWPost;

@interface PAWPostTableViewCell : UITableViewCell

@property (nonatomic, assign, readonly) PAWPostTableViewCellStyle postTableViewCellStyle;

+ (CGSize)sizeThatFits:(CGSize)boundingSize forPost:(PAWPost *)post;

- (instancetype)initWithPostTableViewCellStyle:(PAWPostTableViewCellStyle)style
                               reuseIdentifier:(NSString *)reuseIdentifier;

- (void)updateFromPost:(PAWPost *)post;

@end
