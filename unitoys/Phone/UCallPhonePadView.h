//
//  UCallPhonePadView.h
//  unitoys
//
//  Created by 黄磊 on 2017/2/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UCallPhonePadView : UIView

@property (nonatomic, copy) NSString *currentInputNum;

@property (copy,nonatomic) NSString *inputedPhoneNumber;


typedef void (^UCallInputCompletedBlock)(NSString *btnText,NSInteger btnTag);
@property (nonatomic,copy)UCallInputCompletedBlock completeBlock;

@end
