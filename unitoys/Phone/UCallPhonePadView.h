//
//  UCallPhonePadView.h
//  unitoys
//
//  Created by 黄磊 on 2017/2/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UCallPhoneNumLabel.h"

@interface UCallPhonePadView : UIView

@property (nonatomic, strong) UCallPhoneNumLabel *phoneNumLabel;

@property (nonatomic, copy) NSString *currentInputNum;

@property (copy,nonatomic) NSString *inputedPhoneNumber;


//typedef void (^UCallInputCompletedBlock)(NSString *btnText,NSInteger btnTag);
typedef void (^UCallInputCompletedBlock)(NSString *btnText);
@property (nonatomic,copy)UCallInputCompletedBlock completeBlock;

- (void)hideCallView;

@end
