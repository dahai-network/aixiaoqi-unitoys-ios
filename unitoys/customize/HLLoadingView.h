//
//  HLLoadingView.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HLLoadingView : UIView
// 圆形layer
@property (nonatomic, weak) CAShapeLayer *circleShapeLayer;

// 圆形layer宽度
@property (nonatomic, assign) CGFloat lineWidth;

// 圆形layer颜色
@property (nonatomic, strong) UIColor *borderColor;

@property (nonatomic, readonly, getter=isLoadAnimating) BOOL loadAnimating;

//开始动画
- (void)startAnimating;
//停止动画
- (void)stopAnimating;

@end
