//
//  RoundLable.m
//  unitoys
//
//  Created by sumars on 16/11/16.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "RoundLable.h"

@implementation RoundLable

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [super drawRect:rect];
    self.layer.cornerRadius = rect.size.width/2;
    self.layer.masksToBounds = YES;
    
    
}

@end
