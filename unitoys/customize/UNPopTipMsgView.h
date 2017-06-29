//
//  UNPopTipMsgView.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^PopTipButtonAction)(NSInteger type);
@interface UNPopTipMsgView : UIView
//弹出自定义视图
+ (instancetype)sharePopTipMsgViewTitle:(NSString *)title detailTitle:(NSString *)detail;
- (instancetype)initPopTipMsgViewTitle:(NSString *)title detailTitle:(NSString *)detail;

@property (nonatomic, copy) NSString *leftButtonText;
@property (nonatomic, copy) NSString *rightButtonText;

@property (nonatomic, copy) PopTipButtonAction popTipButtonAction;
@property (nonatomic, assign) CGFloat topOffset;
@end
