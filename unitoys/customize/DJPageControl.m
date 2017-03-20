//
//  DJPageControl.m
//  unitoys
//
//  Created by 董杰 on 2017/3/20.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "DJPageControl.h"

@implementation DJPageControl

//- (void) setCurrentPage:(NSInteger)page {
//    
//    [super setCurrentPage:page];
//    
//    for (NSUInteger subviewIndex = 0; subviewIndex < [self.subviews count]; subviewIndex++) {
//        
//        UIImageView* subview = [self.subviews objectAtIndex:subviewIndex];
//        
//        CGSize size;
//        
//        size.height = 10;
//        
//        size.width = 10;
//        
//        [subview setFrame:CGRectMake(subview.frame.origin.x, subview.frame.origin.y,
//                                     
//                                     size.width,size.height)];
//        
//        
//        
//    }
//
//}

//2.如果只改变当前选中的点的大小，前面加个判断就可以了：

- (void) setCurrentPage:(NSInteger)page {
    
    [super setCurrentPage:page];
    
    for (NSUInteger subviewIndex = 0; subviewIndex < [self.subviews count]; subviewIndex++) {
        
        UIImageView* subview = [self.subviews objectAtIndex:subviewIndex];
        
        CGSize size;
        
        size.height = 8;
        
        if (subviewIndex == page) {
            size.width = 12;
        } else {
            size.width = 8;
        }
        
        [subview setFrame:CGRectMake(subview.frame.origin.x, subview.frame.origin.y,
                                     
                                     size.width,size.height)];
        
        
        
    }
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
