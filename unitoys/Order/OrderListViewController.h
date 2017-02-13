
//
//  OrderListViewController.h
//  unitoys
//
//  Created by sumars on 16/9/29.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"

@interface OrderListViewController : BaseTableController<NSURLConnectionDelegate>

@property (strong,nonatomic) NSMutableArray *arrOrderData;

@end
