//
//  BindDeviceViewController.h
//  unitoys
//
//  Created by sumars on 16/11/16.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"
#import "WaterIdentifyView.h"

@interface BindDeviceViewController : BaseTableController
@property (weak, nonatomic) IBOutlet UIView *headView;//背景图层
@property (nonatomic, strong) WaterIdentifyView *customView;//电量图层
@property (weak, nonatomic) IBOutlet UILabel *hintLabel;//提示文字
@property (weak, nonatomic) IBOutlet UILabel *versionNumber;//版本号
@property (weak, nonatomic) IBOutlet UILabel *macAddress;//mac地址


@end
