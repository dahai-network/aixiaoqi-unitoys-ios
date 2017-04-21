//
//  UNPopTipMsgView.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNPopTipMsgView.h"

@interface UNPopTipMsgView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

@end

@implementation UNPopTipMsgView

+ (instancetype)sharePopTipMsgViewTitle:(NSString *)title detailTitle:(NSString *)detail
{
    return [[UNPopTipMsgView alloc] initPopTipMsgViewTitle:title detailTitle:detail];
}

- (instancetype)initPopTipMsgViewTitle:(NSString *)title detailTitle:(NSString *)detail
{
    if (self = [super init]) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    
}

@end
