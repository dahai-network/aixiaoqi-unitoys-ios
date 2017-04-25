//
//  UIView+Utils.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UIView+Utils.h"

@implementation UIView (Utils)
- (CGFloat)un_left {
    return self.frame.origin.x;
}


- (void)setUn_left:(CGFloat)un_Left {
    CGRect frame = self.frame;
    frame.origin.x = un_Left;
    self.frame = frame;
}


- (CGFloat)un_top {
    return self.frame.origin.y;
}

- (void)setUn_top:(CGFloat)un_top {
    CGRect frame = self.frame;
    frame.origin.y = un_top;
    self.frame = frame;
}


- (CGFloat)un_right {
    return self.frame.origin.x + self.frame.size.width;
}


- (void)setUn_right:(CGFloat)un_right {
    CGRect frame = self.frame;
    frame.origin.x = un_right - frame.size.width;
    self.frame = frame;
}


- (CGFloat)un_bottom {
    return self.frame.origin.y + self.frame.size.height;
}


- (void)setUn_bottom:(CGFloat)un_bottom {
    CGRect frame = self.frame;
    frame.origin.y = un_bottom - frame.size.height;
    self.frame = frame;
}


- (CGFloat)un_centerX {
    return self.center.x;
}


- (void)setUn_centerX:(CGFloat)un_centerX {
    self.center = CGPointMake(un_centerX, self.center.y);
}

- (CGFloat)un_centerY {
    return self.center.y;
}


- (void)setUn_centerY:(CGFloat)un_centerY {
    self.center = CGPointMake(self.center.x, un_centerY);
}


- (CGFloat)un_width {
    return self.frame.size.width;
}


- (void)setUn_width:(CGFloat)un_width {
    CGRect frame = self.frame;
    frame.size.width = un_width;
    self.frame = frame;
}


- (CGFloat)un_height {
    return self.frame.size.height;
}


- (void)setUn_height:(CGFloat)un_height {
    CGRect frame = self.frame;
    frame.size.height = un_height;
    self.frame = frame;
}


- (CGFloat)un_screenX {
    CGFloat x = 0.0f;
    for (UIView* view = self; view; view = view.superview) {
        x += view.un_left;
    }
    return x;
}


- (CGFloat)un_screenY {
    CGFloat y = 0.0f;
    for (UIView* view = self; view; view = view.superview) {
        y += view.un_top;
    }
    return y;
}


- (CGFloat)un_screenViewX {
    CGFloat x = 0.0f;
    for (UIView* view = self; view; view = view.superview) {
        x += view.un_left;
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)view;
            x -= scrollView.contentOffset.x;
        }
    }
    return x;
}


- (CGFloat)un_screenViewY {
    CGFloat y = 0;
    for (UIView* view = self; view; view = view.superview) {
        y += view.un_top;
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)view;
            y -= scrollView.contentOffset.y;
        }
    }
    return y;
}


- (CGRect)un_screenFrame {
    return CGRectMake(self.un_screenViewX, self.un_screenViewY, self.un_width, self.un_height);
}


- (CGPoint)un_origin {
    return self.frame.origin;
}

- (void)setUn_origin:(CGPoint)un_origin {
    CGRect frame = self.frame;
    frame.origin = un_origin;
    self.frame = frame;
}


- (CGSize)un_size {
    return self.frame.size;
}


- (void)setUn_size:(CGSize)un_size {
    CGRect frame = self.frame;
    frame.size = un_size;
    self.frame = frame;
}


- (CGFloat)un_orientationWidth {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
    ? self.un_height : self.un_width;
}


- (CGFloat)un_orientationHeight {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
    ? self.un_width : self.un_height;
}


- (CGPoint)offsetFromView:(UIView*)otherView {
    CGFloat x = 0.0f, y = 0.0f;
    for (UIView* view = self; view && view != otherView; view = view.superview) {
        x += view.un_left;
        y += view.un_top;
    }
    return CGPointMake(x, y);
}
@end
