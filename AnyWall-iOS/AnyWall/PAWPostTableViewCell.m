//
//  PAWPostTableViewCell.m
//  Anywall
//
//  Copyright (c) 2014 Parse Inc. All rights reserved.
//

#import "PAWPostTableViewCell.h"

#import "PAWPost.h"

CGFloat const PAWPostTableViewCellLabelsFontSize = 15.0f;

static CGFloat const PAWPostTableViewCellBackgroundImageLeadingSideInset = 5.5f;

static UIEdgeInsets const PAWPostTableViewCellContentInset = {.top = 5.0f, .left = 0.0f, .bottom = 1.0f, .right = 0.0f};
static UIEdgeInsets const PAWPostTableViewCellTextContentInset = {.top = 6.0f, .left = 10.5f, .bottom = 5.0f, .right = 10.5f};

static CGFloat const PAWPostTableViewCellDetailTextLabelTopInset = 3.0f;

@interface PAWPostTableViewCell ()
{
    UIImageView *_backgroundImageView;
}

@property (nonatomic, assign, readwrite) PAWPostTableViewCellStyle postTableViewCellStyle;

@end

@implementation PAWPostTableViewCell

#pragma mark -
#pragma mark Class

+ (CGSize)sizeThatFits:(CGSize)boundingSize forPost:(PAWPost *)post {
    CGRect bounds = CGRectMake(0.0f, 0.0f, boundingSize.width, boundingSize.height);
    bounds = UIEdgeInsetsInsetRect(bounds, PAWPostTableViewCellContentInset);
    bounds = UIEdgeInsetsInsetRect(bounds, PAWPostTableViewCellTextContentInset);
    boundingSize = bounds.size;

    NSString *text = post.title;
    NSString *username = post.subtitle;

    NSDictionary *textAttributes = @{ NSFontAttributeName : [self postTableViewCellStyleLabelsFont] };

    // Calculate what the frame to fit the post text and the username
    CGRect textRect = [text boundingRectWithSize:boundingSize
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:textAttributes
                                         context:nil];

    CGRect nameRect = [username boundingRectWithSize:boundingSize
                                             options:NSStringDrawingTruncatesLastVisibleLine
                                          attributes:textAttributes
                                             context:nil];

    CGSize size = CGSizeZero;
    size.width = ceilf(boundingSize.width +
                       PAWPostTableViewCellContentInset.left +
                       PAWPostTableViewCellContentInset.right +
                       PAWPostTableViewCellTextContentInset.left +
                       PAWPostTableViewCellTextContentInset.right);
    size.height = ceilf(CGRectGetHeight(textRect) +
                        CGRectGetHeight(nameRect) +
                        PAWPostTableViewCellContentInset.top +
                        PAWPostTableViewCellContentInset.bottom +
                        PAWPostTableViewCellDetailTextLabelTopInset +
                        PAWPostTableViewCellTextContentInset.top +
                        PAWPostTableViewCellTextContentInset.bottom);
    return size;
}

#pragma mark Private

+ (UIFont *)postTableViewCellStyleLabelsFont {
    return [UIFont systemFontOfSize:PAWPostTableViewCellLabelsFontSize];
}

+ (UIImage *)backgroundImageForPostTableViewCellStyle:(PAWPostTableViewCellStyle)style {
    switch (style) {
        case PAWPostTableViewCellStyleLeft:
            return [UIImage imageNamed:@"bubble_grey"];
            break;
        case PAWPostTableViewCellStyleRight:
            return [UIImage imageNamed:@"bubble_green"];
            break;
    }
    return nil;
}

+ (UIColor *)textLabelColorForPostTableViewCellStyle:(PAWPostTableViewCellStyle)style {
    switch (style) {
        case PAWPostTableViewCellStyleLeft:
            return [UIColor blackColor];
            break;
        case PAWPostTableViewCellStyleRight:
            return [UIColor whiteColor];
            break;
    }

    return nil;
}

+ (UIColor *)detailTextLabelColorForPostTableViewCellStyle:(PAWPostTableViewCellStyle)style {
    switch (style) {
        case PAWPostTableViewCellStyleLeft:
            return [UIColor colorWithRed:43.0f/255.0f green:181.0f/255.0f blue:46.0f/255.0f alpha:1.0f];
            break;
        case PAWPostTableViewCellStyleRight:
            return [UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
            break;
    }

    return nil;
}

#pragma mark -
#pragma mark Init

- (instancetype)initWithPostTableViewCellStyle:(PAWPostTableViewCellStyle)style
                               reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        _postTableViewCellStyle = style;

        _backgroundImageView = [[UIImageView alloc] initWithImage:[[self class] backgroundImageForPostTableViewCellStyle:style]];
        [self.contentView addSubview:_backgroundImageView];

        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [[self class] postTableViewCellStyleLabelsFont];
        self.textLabel.textColor = [[self class] textLabelColorForPostTableViewCellStyle:style];
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.numberOfLines = 0;

        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.font = [[self class] postTableViewCellStyleLabelsFont];
        self.detailTextLabel.textColor = [[self class] detailTextLabelColorForPostTableViewCellStyle:style];
    }
    return self;
}

#pragma mark -
#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    const CGRect bounds = UIEdgeInsetsInsetRect(self.contentView.bounds, PAWPostTableViewCellContentInset);
    CGRect textBounds = UIEdgeInsetsInsetRect(bounds, PAWPostTableViewCellTextContentInset);

    NSDictionary *textAttributes = @{ NSFontAttributeName : self.textLabel.font };

    // Set the cell element content sizes
    CGRect textLabelFrame = [self.textLabel.text boundingRectWithSize:textBounds.size
                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                           attributes:textAttributes
                                                              context:nil];
    textLabelFrame.origin.x += textBounds.origin.x;
    textLabelFrame.origin.y += textBounds.origin.y;
    self.textLabel.frame = CGRectIntegral(textLabelFrame);

    CGRect detailTextLabelFrame = [self.detailTextLabel.text boundingRectWithSize:textBounds.size
                                                                          options:NSStringDrawingTruncatesLastVisibleLine
                                                                       attributes:textAttributes
                                                                          context:nil];
    detailTextLabelFrame.origin.x += textBounds.origin.x;
    detailTextLabelFrame.origin.y += CGRectGetMaxY(textLabelFrame) + PAWPostTableViewCellDetailTextLabelTopInset;
    self.detailTextLabel.frame = CGRectIntegral(detailTextLabelFrame);

    CGRect backgroundImageViewFrame = bounds;
    backgroundImageViewFrame.origin.x += (self.postTableViewCellStyle == PAWPostTableViewCellStyleLeft ?
                                          0.0f :
                                          PAWPostTableViewCellBackgroundImageLeadingSideInset);
	backgroundImageViewFrame.size.width -= PAWPostTableViewCellBackgroundImageLeadingSideInset;
    _backgroundImageView.frame = backgroundImageViewFrame;
}

#pragma mark -
#pragma mark Update

- (void)updateFromPost:(PAWPost *)post {
    self.textLabel.text = post.title;
    self.detailTextLabel.text = post.subtitle;
    [self setNeedsLayout];
}

@end
