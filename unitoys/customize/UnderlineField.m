//
//  UnderlineField.m
//  CloudEgg
//
//  Created by sumars on 16/1/11.
//  Copyright © 2016年 ququ-iOS. All rights reserved.
//

#import "UnderlineField.h"

@implementation UnderlineField

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)drawRect:(CGRect)rect {
    if (_bDrawBorder) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (self.backgroundColor==[UIColor whiteColor]) {
            CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
        }else{
            CGContextSetFillColorWithColor(context, [UIColor colorWithRed:125/255.0 green:134/255.0 blue:152/255.0 alpha:1.0].CGColor);
        }
        
        CGContextFillRect(context, CGRectMake(0, CGRectGetHeight(self.frame) - 0.5, CGRectGetWidth(self.frame), 0.5));
    }
    
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds
{

    CGRect iconRect = [super leftViewRectForBounds:bounds];
    iconRect.origin.x += 10;
    return iconRect;
    /*
    CGRect inset = CGRectMake(bounds.origin.x, bounds.origin.y, 45, bounds.size.height);
    //     CGRect inset = CGRectMake(bounds.origin.x +8, bounds.origin.y, 20, bounds.size.height);
    return inset;
    //return CGRectInset(bounds,50,0);*/
}
@end
