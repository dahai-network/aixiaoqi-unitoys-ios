//
//  CustomRefreshMessageHeader.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/17.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CustomRefreshMessageHeader.h"

@implementation CustomRefreshMessageHeader

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (instancetype)headerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock
{
    CustomRefreshMessageHeader *header = [super headerWithRefreshingBlock:refreshingBlock];
    header.lastUpdatedTimeLabel.hidden = YES;
    header.stateLabel.hidden = YES;
//    header.arrowView.hidden = YES;
    header.arrowView.image = [UIImage new];
    return header;
}


@end
