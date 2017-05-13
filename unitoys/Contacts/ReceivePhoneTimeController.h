//
//  ReceivePhoneTimeController.h
//  unitoys
//
//  Created by 黄磊 on 2017/5/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"

typedef void(^ReloadDataWithReceivePhoneTime)();
@interface ReceivePhoneTimeController : BaseViewController

@property (nonatomic, copy) NSString *packageID;
@property (nonatomic, copy) NSString *packageName;
@property (nonatomic, assign) BOOL isAlreadyReceive;

@property (nonatomic, copy) ReloadDataWithReceivePhoneTime reloadDataWithReceivePhoneTime;

@end
