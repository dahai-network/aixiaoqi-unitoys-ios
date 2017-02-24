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


//+ (UIImage *)clipImage:(UIImage *)image toRect:(CGSize)size{
//    
//    //被切图片宽比例比高比例小 或者相等，以图片宽进行放大
//    if (image.size.width*size.height <= image.size.height*size.width) {
//        
//        //以被剪裁图片的宽度为基准，得到剪切范围的大小
//        CGFloat width  = image.size.width;
//        CGFloat height = image.size.width * size.height / size.width;
//        
//        // 调用剪切方法
//        // 这里是以中心位置剪切，也可以通过改变rect的x、y值调整剪切位置
//        return [self imageFromImage:image inRect:CGRectMake(0, (image.size.height -height)/2, width, height)];
//        
//    }else{ //被切图片宽比例比高比例大，以图片高进行剪裁
//        
//        // 以被剪切图片的高度为基准，得到剪切范围的大小
//        CGFloat width  = image.size.height * size.width / size.height;
//        CGFloat height = image.size.height;
//        
//        // 调用剪切方法
//        // 这里是以中心位置剪切，也可以通过改变rect的x、y值调整剪切位置
//        return [self imageFromImage:image inRect:CGRectMake((image.size.width -width)/2, 0, width, height)];
//    }
//    return nil;
//}


/**
 *从图片中按指定的位置大小截取图片的一部分
 * UIImage image 原始的图片
 * CGRect rect 要截取的区域
 */
//+(UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect{
//    
//    //将UIImage转换成CGImageRef
//    CGImageRef sourceImageRef = [image CGImage];
//    
//    //按照给定的矩形区域进行剪裁
//    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
//    
//    //将CGImageRef转换成UIImage
//    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
//    
//    CFRelease(newImageRef);
//    //返回剪裁后的图片
//    return newImage;
//}


/**
 *将图片缩放到指定的CGSize大小
 * UIImage image 原始的图片
 * CGSize size 要缩放到的大小
 */
+(UIImage*)image:(UIImage *)image scaleToSize:(CGSize)size{
    
    // 得到图片上下文，指定绘制范围
    UIGraphicsBeginImageContext(size);
    
    // 将图片按照指定大小绘制
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    // 从当前图片上下文中导出图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 当前图片上下文出栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}

@end
