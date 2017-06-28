//
//  ChooseWhereCardsViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/6/28.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ChooseWhereCardsViewController.h"
#import "ChooseWhereCardsTableViewCell.h"
#import "BlueToothDataManager.h"
#import "OrderActivationViewController.h"

@interface ChooseWhereCardsViewController ()

@end

@implementation ChooseWhereCardsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"爱小器SIM卡在哪里";
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - tableView代理方法
#pragma mark 返回行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

#pragma mark 返回行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 305;
}

#pragma mark 返回cell内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier=@"ChooseWhereCardsTableViewCell";
    ChooseWhereCardsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell=[[[NSBundle mainBundle] loadNibNamed:@"ChooseWhereCardsTableViewCell" owner:nil options:nil] firstObject];
        [cell.btnSimInDevice addTarget:self action:@selector(simInDeviceAction) forControlEvents:UIControlEventTouchUpInside];
        [cell.btnSimCardInPhone addTarget:self action:@selector(simCardInPhoneAction) forControlEvents:UIControlEventTouchUpInside];
    }
    if (![BlueToothDataManager shareManager].isConnected) {
        cell.lblDeviceStatue.text = @"未连接";
    }
    if (![BlueToothDataManager shareManager].isBounded) {
        cell.lblDeviceStatue.text = @"未绑定";
    }
    if (![BlueToothDataManager shareManager].isHaveCard || ![[BlueToothDataManager shareManager].cardType isEqualToString:@"1"]) {
        cell.lblSimCardStatue.text = @"请插入爱小器卡";
    }
    return cell;
}

#pragma mark 爱小器卡在设备中
- (void)simInDeviceAction {
    [self activityOrderActivitedWithID:self.orderID];
}

- (void)activityOrderActivitedWithID:(NSString *)orderID {
    if ([BlueToothDataManager shareManager].isConnected) {
        if ([BlueToothDataManager shareManager].isHaveCard && [[BlueToothDataManager shareManager].cardType isEqualToString:@"1"]) {
            //1.蓝牙连接之后才能走激活的接口
            [BlueToothDataManager shareManager].isShowHud = YES;
            HUDNoStop1(INTERNATIONALSTRING(@"正在激活..."))
            //2.套餐激活完成之后获取蓝牙发送的序列号
            [BlueToothDataManager shareManager].bleStatueForCard = 1;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"checkBLESerialNumber" object:orderID];
        } else {
            HUDNormal(INTERNATIONALSTRING(@"请插入爱小器卡"))
        }
    } else {
        HUDNormal(INTERNATIONALSTRING(@"请连接蓝牙"))
    }
}

#pragma mark 爱小器卡在手机中
- (void)simCardInPhoneAction {
    HUDNormal(@"在手机中")
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
