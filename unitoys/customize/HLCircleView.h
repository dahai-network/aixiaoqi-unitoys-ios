//
//  HLCircleView.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/19.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HLCircleView : UIView

@property (nonatomic, strong) CAShapeLayer *circleShapeLayer;

//进度
@property (nonatomic, assign) CGFloat strokeEnd;

//是否正在旋转
@property (nonatomic, assign) BOOL isRotating;

//边框颜色
@property (nonatomic, strong) UIColor *borderColor;

//边框宽度
@property (nonatomic, assign) CGFloat borderWidth;

//开始旋转动画
- (void)startRotateAnimation;
//结束旋转动画
- (void)stopRotateAnimation;
@end
