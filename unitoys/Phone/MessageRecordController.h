//
//  MessageRecordController.h
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

//#import "BaseTableController.h"
#import "BaseViewController.h"

@interface MessageRecordController : BaseViewController
@property (nonatomic, strong) UINavigationController *nav;

@property (copy,nonatomic) NSArray *arrMessageRecord;
@property (nonatomic, assign) NSInteger page;  //当前短信页码
@property (nonatomic, strong)NSDictionary *userInfo;
@end
