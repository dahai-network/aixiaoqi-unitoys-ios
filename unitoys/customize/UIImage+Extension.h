//
//  UIImage+Extension.h
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage(Extension)

+ (UIImage *)resizableImage:(NSString *)name;
+ (UIImage *)resizableImage1:(NSString *)name;


//+ (UIImage *)clipImage:(UIImage *)image toRect:(CGSize)size;
//+ (UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect;
+(UIImage*)image:(UIImage *)image scaleToSize:(CGSize)size;
@end
