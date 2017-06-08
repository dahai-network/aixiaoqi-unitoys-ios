//
//  UNReadyActivateController.h
//  unitoys
//
//  Created by 黄磊 on 2017/6/7.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface UNReadyActivateController : BaseViewController

@property (nonatomic, copy) NSString *defaultDate;
@property (nonatomic, copy) NSString *defaultDay;

@property (nonatomic, copy) NSString *orderID;
@property (nonatomic, assign) BOOL isAlreadyActivate;

@property (nonatomic, assign) NSTimeInterval lastActivateDate;

@end
