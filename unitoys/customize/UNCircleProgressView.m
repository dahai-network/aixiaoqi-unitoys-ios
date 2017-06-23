//
//  UNCircleProgressView.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/23.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNCircleProgressView.h"

@interface UNCircleProgressView()

@property (nonatomic, strong) CAShapeLayer *outCircleLayer;



@end

@implementation UNCircleProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSubViews];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initSubViews];
}

- (void)initSubViews
{
    
}


@end
