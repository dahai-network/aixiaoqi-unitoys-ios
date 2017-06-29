//
//  UCallPhoneNumLabel.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AddTouchAreaButton;
typedef void(^PhoneLabelChangeBlock)(NSString *currentText, NSString *currentNum);
//typedef void(^PhoneLabelChangeWithSystemBlock)(NSString *currentText, NSString *currentNum);
@interface UCallPhoneNumLabel : UIView
//是否能长按出现复制粘贴
@property (nonatomic, assign) BOOL isCanTouch;

@property (nonatomic, strong) UILabel *phonelabel;
//删除
@property (nonatomic, strong) AddTouchAreaButton *deleteButton;
//输入文字改变回调
@property (nonatomic, copy) PhoneLabelChangeBlock phoneLabelChangeBlock;

- (void)updatePhoneLabel:(NSString *)phone currentNum:(NSString *)number;

@end
