//
//  UITableView+RegisterNib.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UITableView+RegisterNib.h"

@implementation UITableView (RegisterNib)

- (void)registerNibWithNibId:(NSString *)nibId
{
    [self registerNib:[UINib nibWithNibName:nibId bundle:nil] forCellReuseIdentifier:nibId];
}

@end
