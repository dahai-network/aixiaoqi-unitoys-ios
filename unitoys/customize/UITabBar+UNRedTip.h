//
//  UITabBar+UNRedTip.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITabBar (UNRedTip)

- (void)showBadgeOnItemIndex:(NSInteger)index; // 显示小红点
- (void)hideBadgeOnItemIndex:(NSInteger)index; // 隐藏小红点

@end
