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
            if (CGRectGetMaxX(self.titleLabel.frame) - self.imageView.left < self.margin) {
                self.titleLabel.left = CGRectGetMaxY(self.imageView.frame) + self.margin;
            }
        }
            break;
        
        case UIButtonImageInsetsTypeRight:
        {
            if (self.titleLabel.left > self.imageView.left) {
                CGFloat imageX = self.imageView.left;
                CGFloat titleW = self.titleLabel.width;
                CGFloat margin;
                if (self.margin != 0) {
                    margin = self.margin;
                }else{
                    margin = self.titleLabel.left - CGRectGetMaxX(self.imageView.frame);
                }
                self.titleLabel.left = imageX;
                self.imageView.left = imageX + titleW + margin;
            }
        }
            break;
        case UIButtonImageInsetsTypeTop:
        {
            if (CGRectGetMaxY(self.imageView.frame) > self.titleLabel.top) {
                self.imageView.top = _imageTop;
                CGFloat iamgeMaxY = CGRectGetMaxY(self.imageView.frame);
                self.imageView.centerX = self.width * 0.5;
                self.titleLabel.top = iamgeMaxY + self.margin;
                [self.titleLabel sizeToFit];
                self.titleLabel.centerX = self.imageView.centerX;
            }
        }
            break;
        case UIButtonImageInsetsTypeBottom:
        {
            if (CGRectGetMaxY(self.titleLabel.frame) > self.imageView.top) {
                CGFloat titleY = 0;
                CGFloat titleH = self.titleLabel.height;
                
                self.titleLabel.top = titleY;
                self.titleLabel.centerX = self.width * 0.5;
                self.imageView.top = titleH + self.margin;
                self.imageView.centerX = self.width * 0.5;
            }
        }
            break;
        default:
            break;
    }
    
}

@end
