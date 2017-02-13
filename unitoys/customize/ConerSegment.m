//
//  ConerSegment.m
//  unitoys
//
//  Created by sumars on 16/10/7.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "ConerSegment.h"

@implementation ConerSegment

- (void)drawRect:(CGRect)rect {
    [self.layer setMasksToBounds:YES];
    if (_arcValue==0) {
        [self.layer setCornerRadius:3];
    }else
        [self.layer setCornerRadius:_arcValue];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
