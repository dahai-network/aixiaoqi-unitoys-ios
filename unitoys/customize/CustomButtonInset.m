//
//  CustomButtonInset.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/12.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CustomButtonInset.h"
//#import "UIView+RSAdditions.h"
#import "UIView+Utils.h"

@interface CustomButtonInset ()

@end

@implementation CustomButtonInset

+ (instancetype)buttonWithImageInsetsType:(UIButtonImageInsetsType)type WithMargin:(CGFloat)margin
{
    
    //    UIButtonImageInsetsTypeLeft = 0,
    //    UIButtonImageInsetsTypeRight = 1,
    //    UIButtonImageInsetsTypeTop = 2,
    //    UIButtonImageInsetsTypeBottom = 3
    CustomButtonInset *customButton = [[CustomButtonInset alloc] initWithImageInsetsType:type WithMargin:(CGFloat)margin];
    return customButton;
}

- (instancetype)initWithImageInsetsType:(UIButtonImageInsetsType)type WithMargin:(CGFloat)margin
{
    if (self = [super init]) {
        self.imageInsetsType = type;
        self.margin = margin;
    }
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    switch (self.imageInsetsType) {
        case UIButtonImageInsetsTypeLeft:
        {
            if (CGRectGetMaxX(self.titleLabel.frame) - self.imageView.un_left < self.margin) {
                self.titleLabel.un_left = CGRectGetMaxY(self.imageView.frame) + self.margin;
            }
        }
            break;
        
        case UIButtonImageInsetsTypeRight:
        {
            if (self.titleLabel.un_left > self.imageView.un_left) {
                CGFloat imageX = self.imageView.un_left;
                CGFloat titleW = self.titleLabel.un_width;
                CGFloat margin;
                if (self.margin != 0) {
                    margin = self.margin;
                }else{
                    margin = self.titleLabel.un_left - CGRectGetMaxX(self.imageView.frame);
                }
                self.titleLabel.un_left = imageX;
                self.imageView.un_left = imageX + titleW + margin;
            }
        }
            break;
        case UIButtonImageInsetsTypeTop:
        {
            if (CGRectGetMaxY(self.imageView.frame) > self.titleLabel.un_top) {
                self.imageView.un_top = _imageTop;
                CGFloat iamgeMaxY = CGRectGetMaxY(self.imageView.frame);
                self.imageView.un_centerX = self.un_width * 0.5;
                self.titleLabel.un_top = iamgeMaxY + self.margin;
                [self.titleLabel sizeToFit];
                self.titleLabel.un_centerX = self.imageView.un_centerX;
            }
        }
            break;
        case UIButtonImageInsetsTypeBottom:
        {
            if (CGRectGetMaxY(self.titleLabel.frame) > self.imageView.un_top) {
                CGFloat titleY = 0;
                CGFloat titleH = self.titleLabel.un_height;
                
                self.titleLabel.un_top = titleY;
                self.titleLabel.un_centerX = self.un_width * 0.5;
                self.imageView.un_top = titleH + self.margin;
                self.imageView.un_centerX = self.un_width * 0.5;
            }
        }
            break;
        default:
            break;
    }
    
}

@end
