//
//  ConvenienceOrderDetailController.h
//  unitoys
//
//  Created by 黄磊 on 2017/5/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "BaseViewController.h"

@interface ConvenienceOrderDetailController : BaseViewController

@property (nonatomic, copy) NSString *orderDetailId;

//禁止点击详情
@property (nonatomic, assign) BOOL isNoClickDetail;
@end
