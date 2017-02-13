//
//  BorderButton.m
//  unitoys
//
//  Created by sumars on 16/10/24.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BorderButton.h"

@implementation BorderButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)drawRect:(CGRect)rect {
    [self.layer setMasksToBounds:YES];
    [self.layer setCornerRadius:5]; //设置矩形四个圆角半径
    [self.layer setBorderWidth:1.0]; //边框宽度
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef colorref = [[UIColor colorWithRed:0 green:174/255.0 blue:238/255.0 alpha:1] CGColor];
    
    NSLog(@"color space: %@", colorSpace);
    
    [self.layer setBorderColor:colorref];//边框颜色
    
    CGColorSpaceRelease(colorSpace);
}

@end
