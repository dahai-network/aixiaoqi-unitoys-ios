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
        CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
        CGContextFillRect(context, CGRectMake(0, CGRectGetHeight(self.frame) - 0.5, CGRectGetWidth(self.frame), 0.5));
        CGContextFillRect(context, CGRectMake(CGRectGetWidth(self.frame) - 0.5, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)));
    
}

@end
