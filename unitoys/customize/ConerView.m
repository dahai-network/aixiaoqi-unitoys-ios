//
//  ConerView.m
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "ConerView.h"

@implementation ConerView

- (void)drawRect:(CGRect)rect {
    [self.layer setMasksToBounds:YES];
    if (_arcValue==0) {
        [self.layer setCornerRadius:30];
    }else
    [self.layer setCornerRadius:_arcValue];
   
    /*
    
    [self.layer setBorderWidth:1.0]; //边框宽度
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef colorref = [[UIColor colorWithRed:0 green:174/255.0 blue:238/255.0 alpha:1] CGColor];
    
    NSLog(@"color space: %@", colorSpace);
    
    [self.layer setBorderColor:colorref];//边框颜色
    
    CGColorSpaceRelease(colorSpace);*/
}

@end
