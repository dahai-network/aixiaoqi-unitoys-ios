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

#import "UNDatabaseTools.h"
#import "UNMobileActivateController.h"
#import "UNConvertFormatTool.h"

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
    UNDebugLogVerbose(@"爱小器卡已放入手机");
    [self activeSIMCardInPhoneAction];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)activeSIMCardInPhoneAction
{
    if (!self.isAlreadyActivate) {
        //直接获取卡数据
        UNLogLBEProcess(@"activeSIMCardInPhoneAction-激活");
        [self activitySuccess];
        
//        HUDNoStop1(@"")
//        NSDictionary *info = @{@"OrderID":self.orderID, @"BeginDateTime":self.selectDate};
//        NSString *apiNameStr = [NSString stringWithFormat:@"%@OrderID%@", @"apiOrderActivation", self.orderID];
//        [UNNetworkManager postUrl:apiOrderActivation parameters:info success:^(ResponseType type, id  _Nullable responseObj) {
//            HUDStop
//            if (type == ResponseTypeSuccess) {
//                [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
//                [self activitySuccess];
//            }else if (type == ResponseTypeFailed){
//                HUDNormal(responseObj[@"msg"])
//            }
//        } failure:^(NSError * _Nonnull error) {
//            HUDStop
//            NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
//            if (responseObj) {
//                [self activitySuccess];
//            }else{
//                HUDNormal(@"激活失败")
//            }
//        }];
    }else{
        //获取激活码
        [self getActivateCode];
    }
}

#pragma mark 激活成功
- (void)activitySuccess {
    HUDNoStop1(@"")
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.orderID, @"OrderID", nil];
    NSString *apiNameStr = [NSString stringWithFormat:@"%@OrderID%@", @"apiActivationLocalCompleted", self.orderID];
    [UNNetworkManager postUrl:apiActivationLocalCompleted parameters:params success:^(ResponseType type, id  _Nullable responseObj) {
        HUDStop
        if (type == ResponseTypeSuccess) {
            self.isAlreadyActivate = YES;
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            //获取激活码
            [self getActivateCode];
        }else if (type == ResponseTypeFailed){
            UNDebugLogVerbose(@"ResponseTypeFailed----%@", responseObj);
        }
    } failure:^(NSError * _Nonnull error) {
        HUDStop
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            [self getActivateCode];
        }
    }];
}

#pragma mark 查询订单卡数据
- (void)getActivateCode
{
    HUDNoStop1(@"")
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.orderID, @"OrderID", nil];
    NSString *apiNameStr = [NSString stringWithFormat:@"%@OrderID%@", @"apiQueryOrderData", self.orderID];
    [UNNetworkManager postUrl:apiQueryOrderData parameters:params success:^(ResponseType type, id  _Nullable responseObj) {
        UNDebugLogVerbose(@"%@", responseObj);
        HUDStop
        if (type == ResponseTypeSuccess) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            //粘贴激活码
            NSString *code = [self convertActivationCode:responseObj[@"data"][@"Data"]];
            [self pasteCode:code];
            
            UNMobileActivateController * activateVc = [[UNMobileActivateController alloc] init];
            [self.navigationController pushViewController:activateVc animated:YES];
        }else if (type == ResponseTypeFailed){
            NSLog(@"请求失败：%@", responseObj[@"msg"]);
        }
    } failure:^(NSError * _Nonnull error) {
        HUDStop
        HUDNormal(@"网络貌似有问题")
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            NSString *code = [self convertActivationCode:responseObj[@"data"][@"Data"]];
            [self pasteCode:code];
            UNMobileActivateController * activateVc = [[UNMobileActivateController alloc] init];
            [self.navigationController pushViewController:activateVc animated:YES];
        }
    }];
}

//转换激活码
//76372b2f6c35546856465972786a71686e6c43457a704f61367973624263776736717549544238424d3363784a476547304664674b726b465a716c3943556873336578693862337254476f3673686758424a6553383548754c6d737838504149532b3973
- (NSString *)convertActivationCode:(NSString *)code
{
    if (!code || [code isEqualToString:@""]) {
        return nil;
    }
    return [UNConvertFormatTool stringFromHexString:code];
}

//粘贴激活码
- (void)pasteCode:(NSString *)code
{
    if (code) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        [pasteboard setString:code];
    }
}


@end
