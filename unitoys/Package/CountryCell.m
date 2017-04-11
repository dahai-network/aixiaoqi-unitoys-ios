//
//  CountryCell.m
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "CountryCell.h"

@implementation CountryCell

- (void)drawRect:(CGRect)rect {
    
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [UIColor colorWithRed:229.0/255.0 green:229.0/255.0 blue:229.0/255.0 alpha:1.0].CGColor);
        CGContextFillRect(context, CGRectMake(0, CGRectGetHeight(self.frame) - 1, CGRectGetWidth(self.frame), 1));
        CGContextFillRect(context, CGRectMake(CGRectGetWidth(self.frame) - 1, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)));
    
}

@end
