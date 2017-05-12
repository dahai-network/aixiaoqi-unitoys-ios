
//
//  OrderListViewController.h
//  unitoys
//
//  Created by sumars on 16/9/29.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "ZBRreshViewController.h"

@interface OrderListViewController : ZBRreshViewController<NSURLConnectionDelegate>

//是否为境外套餐
@property (nonatomic, assign) BOOL isAbroadMessage;

@end
