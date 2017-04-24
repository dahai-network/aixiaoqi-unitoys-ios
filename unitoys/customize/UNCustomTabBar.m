//
//  UNCustomTabBar.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/24.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNCustomTabBar.h"

@implementation UNCustomTabBar

- (instancetype)init
{
    if (self = [super init]) {
        self.clipsToBounds = NO;
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.clipsToBounds = NO;
}


//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//    UIView *view = [super hitTest:point withEvent:event];
//    if (view == nil) {
//        for (UIView *subView in self.subviews) {
//            if ([subView isKindOfClass:NSClassFromString(@"PhoneOperationPad")]) {
//                if (!subView.isHidden) {
//                    CGPoint p = [subView convertPoint:point fromView:self];
//                    if (CGRectContainsPoint(subView.bounds, p)) {
//                        view = subView;
//                    }
//                }
//            }
//        }
//    }
//    NSLog(@"UNCustomTabBar--hitTest--%@",view);
//    return view;
//}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    for (UIView *subView in self.subviews) {
        if ([subView isKindOfClass:NSClassFromString(@"PhoneOperationPad")]) {
            if (!subView.isHidden) {
                CGPoint p = [subView convertPoint:point fromView:self];
                if (CGRectContainsPoint(subView.bounds, p)) {
                    return YES;
                }
            }
        }
    }
    return [super pointInside:point withEvent:event];
}

@end
