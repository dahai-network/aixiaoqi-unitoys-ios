//
//  UIImage+Extension.m
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "UIImage+Extension.h"

@implementation UIImage (Extension)
/**
 *  返回一张可以随意拉伸不变形的图片
 *
 *  @param name 图片名字
 */
+ (UIImage *)resizableImage:(NSString *)name
{
    UIImage *normal = [UIImage imageNamed:name];
    
//    CGFloat top = 21; // 顶端盖高度
//    CGFloat bottom = 21 ; // 底端盖高度
//    CGFloat left = 20; // 左端盖宽度
//    CGFloat right = 27; // 右端盖宽度
    
    
//    CGFloat top = 16.8; // 顶端盖高度
//    CGFloat bottom = 16.8 ; // 底端盖高度
    CGFloat top = normal.size.height * 0.5; // 顶端盖高度
    CGFloat bottom = normal.size.height * 0.5 ; // 底端盖高度
    CGFloat left = normal.size.width * 0.5; // 左端盖宽度
    CGFloat right = normal.size.width * 0.5; // 右端盖宽度
    UIEdgeInsets insets = UIEdgeInsetsMake(top, left, bottom, right);
    // 指定为拉伸模式，伸缩后重新赋值
    //    image = [image resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
    
    //    CGFloat w = normal.size.width * 0.5;
    //    CGFloat h = normal.size.height * 0.5;
    return [normal resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
}

+ (UIImage *)resizableImage1:(NSString *)name
{
    UIImage *normal = [UIImage imageNamed:name];
    
//    CGFloat top = 21; // 顶端盖高度
//    CGFloat bottom = 21 ; // 底端盖高度
//    CGFloat left = 27; // 左端盖宽度
//    CGFloat right = 20; // 右端盖宽度
    CGFloat top = normal.size.height * 0.5; // 顶端盖高度
    CGFloat bottom = normal.size.height * 0.5 ; // 底端盖高度
    CGFloat left = normal.size.width * 0.5; // 左端盖宽度
    CGFloat right = normal.size.width * 0.5; // 右端盖宽度
    UIEdgeInsets insets = UIEdgeInsetsMake(top, left, bottom, right);
    // 指定为拉伸模式，伸缩后重新赋值
    //    image = [image resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
    
    //    CGFloat w = normal.size.width * 0.5;
    //    CGFloat h = normal.size.height * 0.5;
    return [normal resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
}
@end
