//
//  UITabBar+UNRedTip.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UITabBar+UNRedTip.h"

#define kBadgeViewTag 500  // 红点起始tag值
#define kBadgeWidth  6  // 红点宽高

@implementation UITabBar (UNRedTip)

- (void)showBadgeOnItemIndex:(NSInteger)index
{
    [self removeBadgeOnItemIndex:index];
    UIView *badgeView = [[UIView alloc]init];
    badgeView.tag = kBadgeViewTag + index;
    badgeView.layer.cornerRadius = kBadgeWidth / 2;
    badgeView.backgroundColor = [UIColor redColor];
    [self addSubview:badgeView];
    
    // 设置小红点的位置
    int i = 0;
    for (UIView* subView in self.subviews){
        if ([subView isKindOfClass:NSClassFromString(@"UITabBarButton")]){
            // 找到需要加小红点的view，根据frame设置小红点的位置
            if (i == index) {
                // 数字9为向右边的偏移量，可以根据具体情况调整
                CGFloat x = subView.frame.origin.x + subView.frame.size.width / 2 + 9;
                CGFloat y = 6;
                badgeView.frame = CGRectMake(x, y, kBadgeWidth, kBadgeWidth);
                break;
            }
            i++;
        }
    }
}

// 隐藏小红点
- (void)hideBadgeOnItemIndex:(NSInteger)index{
    [self removeBadgeOnItemIndex:index];
}

// 移除小红点
- (void)removeBadgeOnItemIndex:(NSInteger)index{
    // 根据tag的值移除
    for (UIView *subView in self.subviews) {
        if (subView.tag == kBadgeViewTag + index) {
            [subView removeFromSuperview];
        }
    }
}

@end
