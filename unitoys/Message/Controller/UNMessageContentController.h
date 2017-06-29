//
//  UNMessageContentController.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/2.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface UNMessageContentController : BaseViewController
//是否新建短信
@property (nonatomic, assign) BOOL isNewMessage;
//手机号
@property (nonatomic, copy) NSString *toTelephone;
//昵称
@property (nonatomic, copy) NSString *toPhoneName;

@end
