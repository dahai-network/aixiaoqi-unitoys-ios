//
//  HLDragView.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/17.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "HLDragView.h"

@interface HLDragButton()

//是否已经拖拽过
@property (nonatomic, assign) BOOL isDragged;

@end

@implementation HLDragButton

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    self.userInteractionEnabled = YES;
    self.startPoint = CGPointMake(self.frame.origin.x, self.frame.origin.y);
    self.isDragged = NO;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint currentPoint = [[touches anyObject] locationInView:self];
    self.startPoint = currentPoint;
    [self.superview bringSubviewToFront:self];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint currentPoint = [[touches anyObject] locationInView:self];
    CGFloat offsetX = currentPoint.x - self.startPoint.x;
    CGFloat offsetY = currentPoint.y - self.startPoint.y;
    CGPoint newCenter = CGPointMake(self.center.x + offsetX, self.center.y + offsetY);
    
    CGFloat halfx = CGRectGetMidX(self.bounds);
    //x坐标左边界
    newCenter.x = MAX(halfx, newCenter.x);
    //x坐标右边界
    newCenter.x = MIN(self.superview.bounds.size.width - halfx, newCenter.x);
    
    //y坐标同理
    CGFloat halfy = CGRectGetMidY(self.bounds);
    newCenter.y = MAX(halfy, newCenter.y);
    newCenter.y = MIN(self.superview.bounds.size.height - 49 - halfy, newCenter.y);
    
    self.center = newCenter;
    if (!self.isDragged) {
        self.isDragged = YES;
    }
//    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.isDragged) {
        [super touchesEnded:touches withEvent:event];
    }else{
        self.isDragged = NO;
    }
    [self setHighlighted:NO];
}

@end
