//
//  CustomButtonInset.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/12.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, UIButtonImageInsetsType) {
    UIButtonImageInsetsTypeDefault = 0,
    UIButtonImageInsetsTypeLeft = 1,
    UIButtonImageInsetsTypeRight = 2,
    UIButtonImageInsetsTypeTop = 3,
    UIButtonImageInsetsTypeBottom = 4
};

@interface CustomButtonInset : UIButton

+ (instancetype)buttonWithImageInsetsType:(UIButtonImageInsetsType)type WithMargin:(CGFloat)margin;

- (instancetype)initWithImageInsetsType:(UIButtonImageInsetsType)type WithMargin:(CGFloat)margin;

@property (nonatomic, assign) UIButtonImageInsetsType imageInsetsType;
@property (nonatomic, assign) CGFloat margin;

@property (nonatomic, assign) CGFloat imageTop;
@property (nonatomic, assign) CGFloat imageleft;
@property (nonatomic, assign) CGFloat imageright;

@property (nonatomic, assign) CGFloat titleTop;
@property (nonatomic, assign) CGFloat titleleft;
@property (nonatomic, assign) CGFloat titleright;
@end
