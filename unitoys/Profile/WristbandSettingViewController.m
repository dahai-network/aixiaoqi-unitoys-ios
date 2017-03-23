//
//  WristbandSettingViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/3/22.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "WristbandSettingViewController.h"
#import "WristbandSettingTableViewCell.h"
#import "UNBlueToothTool.h"
#import "BlueToothDataManager.h"

@interface WristbandSettingViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong)NSMutableArray *dataArr;

@end

@implementation WristbandSettingViewController

- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        self.dataArr = [NSMutableArray array];
    }
    return _dataArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSMutableDictionary *dict1 = [NSMutableDictionary dictionaryWithDictionary:@{@"img":@"pro_call", @"lblName":@"来电通知", @"status":@"0"}];
    NSMutableDictionary *dict2 = [NSMutableDictionary dictionaryWithDictionary:@{@"img":@"pro_message", @"lblName":@"短信通知", @"status":@"0"}];
    NSMutableDictionary *dict3 = [NSMutableDictionary dictionaryWithDictionary:@{@"img":@"pro_weichart", @"lblName":@"微信通知", @"status":@"0"}];
    NSMutableDictionary *dict4 = [NSMutableDictionary dictionaryWithDictionary:@{@"img":@"pro_qq", @"lblName":@"QQ通知", @"status":@"0"}];
    self.dataArr = [NSMutableArray arrayWithObjects:dict1, dict2, dict3, dict4, nil];
    self.title = INTERNATIONALSTRING(@"手环设置");
    self.tableView.tableFooterView = [UIView new];
    [self checkUserConfig];
    // Do any additional setup after loading the view from its nib.
}

- (void)checkUserConfig {
    HUDNoStop1(INTERNATIONALSTRING(@"正在加载..."))
    self.checkToken = YES;
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiCheckUserConfig params:nil success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"获取到的用户配置信息 --> %@", responseObj);
            NSArray *arr = responseObj[@"data"];
            if (arr.count) {
                for (NSDictionary *dict in arr) {
                    if ([dict[@"Name"] isEqualToString:@"NotificaCall"]) {
                        //来电
                        [self.dataArr[0] setObject:[dict[@"Status"] intValue]?@"1":@"0" forKey:@"status"];
                    } else if ([dict[@"Name"] isEqualToString:@"NotificaSMS"]) {
                        //短信
                        [self.dataArr[1] setObject:[dict[@"Status"] intValue]?@"1":@"0" forKey:@"status"];
                    } else if ([dict[@"Name"] isEqualToString:@"NotificaWeChat"]) {
                        //微信
                        [self.dataArr[2] setObject:[dict[@"Status"] intValue]?@"1":@"0" forKey:@"status"];
                    }else if ([dict[@"Name"] isEqualToString:@"NotificaQQ"]) {
                        //QQ消息
                        [self.dataArr[3] setObject:[dict[@"Status"] intValue]?@"1":@"0" forKey:@"status"];
                    } else {
                        NSLog(@"这是什么消息？");
                    }
                }
            }
            [self.tableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark - tableView代理方法
#pragma mark 返回行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

#pragma mark 返回行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

#pragma mark 返回cell内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier=@"WristbandSettingTableViewCell";
    WristbandSettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell=[[[NSBundle mainBundle] loadNibNamed:@"WristbandSettingTableViewCell" owner:nil options:nil] firstObject];
        [cell.swiSetting addTarget:self action:@selector(switchOffSetAction:) forControlEvents:UIControlEventValueChanged];
    }
    NSDictionary *dic = self.dataArr[indexPath.row];
    cell.swiSetting.tag = indexPath.row;
    cell.imgSetting.image = [UIImage imageNamed:dic[@"img"]];
    cell.lblSetting.text = dic[@"lblName"];
    if ([dic[@"status"] intValue] == 0) {
        cell.swiSetting.on = NO;
    } else {
        cell.swiSetting.on = YES;
    }
    return cell;
}

- (void)switchOffSetAction:(UISwitch *)sender {
    if ([BlueToothDataManager shareManager].isConnected) {
        int status = sender.on?1:0;
        switch (sender.tag) {
            case 0:
                //来电通知
                [self uploadNotificationStatueWithName:@"NotificaCall" Statue:status];
                break;
            case 1:
                //短信通知
                [self uploadNotificationStatueWithName:@"NotificaSMS" Statue:status];
                break;
            case 2:
                //微信通知
                [self uploadNotificationStatueWithName:@"NotificaWeChat" Statue:status];
                break;
            case 3:
                //QQ通知
                [self uploadNotificationStatueWithName:@"NotificaQQ" Statue:status];
                break;
            default:
                NSLog(@"这是什么鬼通知？");
                break;
        }
    } else {
        HUDNormal(INTERNATIONALSTRING(@"请连接蓝牙"))
        [self.tableView reloadData];
    }
}

- (void)uploadNotificationStatueWithName:(NSString *)name Statue:(int)statue {
    NSString *statueStr = [NSString stringWithFormat:@"%d", statue];
    HUDNoStop1(INTERNATIONALSTRING(@"正在更新状态"))
    self.checkToken = YES;
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:name, @"Name", statueStr, @"Status", nil];
    [self getBasicHeader];
    //        NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiUploadConfig params:info success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            //成功
//            HUDStop;
            HUDNormal(responseObj[@"msg"])
            NSLog(@"更新之后的状态 -- %@", responseObj);
            if ([name isEqualToString:@"NotificaCall"]) {
                //来电
                [self.dataArr[0] setObject:statue?@"1":@"0" forKey:@"status"];
            } else if ([name isEqualToString:@"NotificaSMS"]) {
                //短信
                [self.dataArr[1] setObject:statue?@"1":@"0" forKey:@"status"];
            } else if ([name isEqualToString:@"NotificaWeChat"]) {
                //微信
                [self.dataArr[2] setObject:statue?@"1":@"0" forKey:@"status"];
            }else if ([name isEqualToString:@"NotificaQQ"]) {
                //QQ消息
                [self.dataArr[3] setObject:statue?@"1":@"0" forKey:@"status"];
            } else {
                NSLog(@"这是什么消息？");
            }
            [[UNBlueToothTool shareBlueToothTool] sendDataToCheckIsAllowToNotificationWithPhoneCall:[self.dataArr[0][@"status"] boolValue] Message:[self.dataArr[1][@"status"] boolValue] WeiChart:[self.dataArr[2][@"status"] boolValue] QQ:[self.dataArr[3][@"status"] boolValue]];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            [self.tableView reloadData];
        }else{
            //数据请求失败
            NSLog(@"请求失败：%@", responseObj[@"msg"]);
            HUDNormal(responseObj[@"msg"])
            [self.tableView reloadData];
        }
    } failure:^(id dataObj, NSError *error) {
        NSLog(@"啥都没：%@",[error description]);
        [self.tableView reloadData];
    } headers:self.headers];
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
