//
//  UNCircleProgressView.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/23.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNCircleProgressView.h"

#define CircleColor [UIColor colorWithRed:(0 / 255.0) green:(160 / 255.0) blue:(233 / 255.0) alpha:1.0]
#define kPadding 3.0

@interface UNCircleProgressView()

@end

@implementation UNCircleProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSubViews];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initSubViews];
}

- (void)initSubViews
{
    self.backgroundColor = [UIColor whiteColor];
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) * 0.5;
    CGPoint center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    CGContextAddArc(context, center.x, center.y, radius - 1, 0, 2 * M_PI, YES);
    [CircleColor set];
    CGContextSetLineWidth(context, 1.0);
    CGContextDrawPath(context, kCGPathStroke);
    
    if (_progress != 0) {
        CGContextAddArc(context, center.x, center.y, radius - 1.0, 0, 2 * M_PI, YES);
        [CircleColor set];
        CGContextDrawPath(context, kCGPathFill);
        
        CGFloat progress = 2 * M_PI * _progress - 0.5 * M_PI - 0.00005;
        CGContextMoveToPoint(context, center.x, center.y);
        CGContextAddArc(context, center.x, center.y, radius - 1.5, - 0.5 * M_PI, progress, YES);
        [[UIColor whiteColor] set];
        CGContextDrawPath(context, kCGPathFill);
    }
    [super drawRect:rect];
}

@end
