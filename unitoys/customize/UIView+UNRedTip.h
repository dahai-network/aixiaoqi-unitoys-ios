//
//  UIView+UNRedTip.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (UNRedTip)

@property (nonatomic, strong) UILabel *badgeLabel;

//显示小红点
- (void)showBadge;

//显示小红点消息数量
- (void)showBadgeWithCount:(NSInteger)count;

//隐藏小红点
- (void)hideBadge;

@end
