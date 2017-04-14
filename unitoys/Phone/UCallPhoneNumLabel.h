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
@interface UCallPhoneNumLabel : UIView

@property (nonatomic, strong) UILabel *phonelabel;
@property (nonatomic, strong) AddTouchAreaButton *deleteButton;

@property (nonatomic, copy) PhoneLabelChangeBlock phoneLabelChangeBlock;

- (void)updatePhoneLabel:(NSString *)phone currentNum:(NSString *)number;

@end
