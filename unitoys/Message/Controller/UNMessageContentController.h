//
//  UNMessageContentController.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/2.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface UNMessageContentController : BaseViewController

@property (nonatomic, assign) BOOL isNewMessage;

@property (nonatomic, copy) NSString *toTelephone;
@property (nonatomic, copy) NSString *toPhoneName;

@end
