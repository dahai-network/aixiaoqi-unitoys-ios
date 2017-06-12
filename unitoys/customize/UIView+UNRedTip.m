//
//  UIView+UNRedTip.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UIView+UNRedTip.h"
#import <objc/runtime.h>

static char badgeViewKey;
static NSInteger const pointWidth = 5; //小红点的宽高
static NSInteger const rightRange = 2; //距离控件右边的距离
static CGFloat const badgeFont = 9; //字体的大小

@implementation UIView (UNRedTip)
//显示小红点
- (void)showBadge
{
//    if (self.badgeLabel == nil) {
//        CGRect frame = CGRectMake(CGRectGetWidth(self.frame) + rightRange, -pointWidth / 2, pointWidth, pointWidth);
//        self.badgeLabel = [[UILabel alloc] initWithFrame:frame];
//        self.badgeLabel.backgroundColor = [UIColor redColor];
//        //圆角为宽度的一半
//        self.badgeLabel.layer.cornerRadius = pointWidth / 2;
//        //确保可以有圆角
//        self.badgeLabel.layer.masksToBounds = YES;
//        [self addSubview:self.badgeLabel];
//        [self bringSubviewToFront:self.badgeLabel];
//    }
    [self showBadgeWithRightMargin:0 TopMargin:0];
}

- (void)showBadgeWithRightMargin:(CGFloat)rightMargin TopMargin:(CGFloat)topMargin
{
    if (self.badgeLabel == nil) {
        CGRect frame = CGRectMake(CGRectGetWidth(self.frame) + rightRange - rightMargin, -pointWidth / 2 + topMargin, pointWidth, pointWidth);
        self.badgeLabel = [[UILabel alloc] initWithFrame:frame];
        self.badgeLabel.backgroundColor = [UIColor redColor];
        //圆角为宽度的一半
        self.badgeLabel.layer.cornerRadius = pointWidth / 2;
        //确保可以有圆角
        self.badgeLabel.layer.masksToBounds = YES;
        [self addSubview:self.badgeLabel];
        [self bringSubviewToFront:self.badgeLabel];
    }
}


//显示小红点消息数量
- (void)showBadgeWithCount:(NSInteger)count
{
    if (count < 0) {
        [self hideBadge];
        return;
    }
    [self showBadge];
    if (count > 0) {
        self.badgeLabel.textColor = [UIColor whiteColor];
        self.badgeLabel.font = [UIFont systemFontOfSize:badgeFont];
        self.badgeLabel.textAlignment = NSTextAlignmentCenter;
        self.badgeLabel.text = (count > 99 ? [NSString stringWithFormat:@"99+"] : [NSString stringWithFormat:@"%@", @(count)]);
        [self.badgeLabel sizeToFit];
        CGRect frame = self.badgeLabel.frame;
        frame.size.width += 4;
        frame.size.height += 4;
        frame.origin.y = -frame.size.height / 2;
        if (CGRectGetWidth(frame) < CGRectGetHeight(frame)) {
            frame.size.width = CGRectGetHeight(frame);
        }
        self.badgeLabel.frame = frame;
        self.badgeLabel.layer.cornerRadius = CGRectGetHeight(self.badgeLabel.frame) / 2;
    }
}
//隐藏小红点
- (void)hideBadge
{
    if (self.badgeLabel) {
        [self.badgeLabel removeFromSuperview];
        self.badgeLabel = nil;
    }
}

- (UILabel *)badgeLabel
{
    return objc_getAssociatedObject(self, &badgeViewKey);
}
- (void)setBadgeLabel:(UILabel *)badgeLabel
{
    objc_setAssociatedObject(self, &badgeViewKey, badgeLabel, OBJC_ASSOCIATION_RETAIN);
}

@end
