//
//  CallPackageDetailsController.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CallPackageDetailsController.h"

@interface CallPackageDetailsController ()

@end

@implementation CallPackageDetailsController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
}

- (void)initData
{
    self.title = @"套餐详情";
    self.fristNameLabel.text = @"500分钟通话套餐";
    self.fristRightLabel.text = @"￥10.0";
    self.userDescLabel.text = @"该套餐包含1个月双卡双待服务和500分钟拨打时长两部分。双卡双待服务是指将国内电话卡插入到爱小器智能硬件中后，通过爱小器APP能够接打电话，收发短信。支持移动、联通、电信三大运营商电话卡。500分钟通话时长是指使用APP拨打电话时，选择网络电话。如果选择手环电话，将不扣除该通话时长。";
    self.careRuleLabel.text = @"该套餐从购买日开始，30天内有效。";
    [self.buyButton addTarget:self action:@selector(buyClick) forControlEvents:UIControlEventTouchUpInside];
}

- (void)buyClick
{
    NSLog(@"点击购买");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 100;
//}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    return nil;
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
