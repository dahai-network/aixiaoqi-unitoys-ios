//
//  UNCircleProgressView.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/23.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNCircleProgressView.h"

#define CircleColor [UIColor colorWithRed:(0 / 255.0) green:(160 / 255.0) blue:(233 / 255.0) alpha:1.0]
#define kPadding 4.0

@interface UNCircleProgressView()

//@property (nonatomic, strong) CAShapeLayer *outCircleLayer;
//
//@property (nonatomic, strong) CAShapeLayer *inCircleLayer;

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
    CGContextAddArc(context, center.x, center.y, radius, 0, 2 * M_PI, YES);
    [[UIColor whiteColor] set];
    CGContextDrawPath(context, kCGPathFill);
    
    if (_progress != 0) {
        CGFloat progress = 2 * M_PI * _progress;
        CGContextAddArc(context, center.x, center.y, radius - kPadding, 0, progress, YES);
        [CircleColor set];
        //    CGContextFillPath(context);
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    [super drawRect:rect];
}

//- (void)drawRect:(CGRect)rect
//{
//        CGFloat radius = (MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) / 2) - kPadding;
//        CGPoint center = CGPointMake(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) / 2);
//        UIBezierPath *coverPath = [UIBezierPath bezierPath]; //empty path
//        [coverPath setLineWidth:kPadding];
//        [coverPath addArcWithCenter:center radius:radius startAngle:0 endAngle:2 * M_PI clockwise:YES]; //add the arc
//        [CircleColor set];
//        [coverPath stroke];
//}

@end
