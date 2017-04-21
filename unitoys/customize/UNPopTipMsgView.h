//
//  UNPopTipMsgView.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UNPopTipMsgView : UIView

+ (instancetype)sharePopTipMsgViewTitle:(NSString *)title detailTitle:(NSString *)detail;

- (instancetype)initPopTipMsgViewTitle:(NSString *)title detailTitle:(NSString *)detail;

@end
