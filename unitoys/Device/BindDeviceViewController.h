//
//  BindDeviceViewController.h
//  unitoys
//
//  Created by sumars on 16/11/16.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"
#import "LXWaveProgressView.h"

@interface BindDeviceViewController : BaseTableController
@property (weak, nonatomic) IBOutlet UIView *headView;//背景图层
@property (nonatomic, strong) LXWaveProgressView *customView;//电量图层
//@property (weak, nonatomic) IBOutlet UILabel *hintLabel;//提示文字
@property (weak, nonatomic) IBOutlet UILabel *versionNumber;//版本号
@property (weak, nonatomic) IBOutlet UILabel *macAddress;//mac地址
@property (nonatomic, copy) NSString *hintStrFirst;//提示文字前半段文字
@property (nonatomic, assign) BOOL isBeingNet;//是否正在进行网络请求
@property (weak, nonatomic) IBOutlet UILabel *deviceName;//设备名称
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;


@end
