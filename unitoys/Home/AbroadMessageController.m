//
//  AbroadMessageController.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "AbroadMessageController.h"
#import "OrderCell.h"
#import "ActivateGiftCardViewController.h"

@interface AbroadMessageController ()

@end

@implementation AbroadMessageController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initData];
    
    [self checkOrderList];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkOrderList) name:@"actionOrderSuccess" object:@"actionOrderSuccess"];//激活成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkOrderList) name:@"BuyConfrim" object:nil];//取消
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkOrderList) name:@"boundGiftCardSuccess" object:@"boundGiftCardSuccess"];//绑定礼包卡成功
}

- (void)initData
{
    self.tableView.tableFooterView = [UIView new];
    self.title = @"已购境外套餐";
    [self.tableView registerNib:[UINib nibWithNibName:@"OrderCell" bundle:nil] forCellReuseIdentifier:@"OrderCell"];
}

- (void)checkOrderList {
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:@"20",@"PageSize",@"1",@"PageNumber", nil];
    
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    
    
    [SSNetworkRequest getRequest:apiOrderList params:params success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            self.arrOrderData = [[responseObj objectForKey:@"data"] objectForKey:@"list"];
            
            [self.tableView reloadData];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        NSLog(@"查询到的套餐数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrOrderData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OrderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OrderCell"];
    
    NSDictionary *dicOrder = [self.arrOrderData objectAtIndex:indexPath.row];
    [cell.ivLogoPic sd_setImageWithURL:[NSURL URLWithString:[dicOrder objectForKey:@"LogoPic"]]];
    cell.lblFlow.text = [dicOrder objectForKey:@"PackageName"];//[NSString stringWithFormat:@"流量:%dMB",[[dicOrder objectForKey:@"Flow"] intValue]/1024];
    cell.lblExpireDays.text = [dicOrder objectForKey:@"ExpireDays"];
//    cell.lblTotalPrice.text = [NSString stringWithFormat:@"￥%.2f",[[dicOrder objectForKey:@"TotalPrice"] floatValue]];
//    cell.lblTotalPrice.font = [UIFont systemFontOfSize:15 weight:2];
    if ([[dicOrder objectForKey:@"PayStatus"] intValue]==0) {
        NSLog(@"未支付");
    }else{
        //order_actived
        switch ([[dicOrder objectForKey:@"OrderStatus"] intValue]) {
            case 0:
                [cell.btnOrderStatus setTitle:@"未激活" forState:UIControlStateNormal];
                [cell.btnOrderStatus setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                [cell.btnOrderStatus setImage:[UIImage imageNamed:@"order_unactive"] forState:UIControlStateNormal];
                break;
            case 1:
                if ([[dicOrder objectForKey:@"PackageCategory"] intValue] == 1) {
                    [cell.btnOrderStatus setTitle:[NSString stringWithFormat:@"剩余%@分钟", dicOrder[@"RemainingCallMinutes"]] forState:UIControlStateNormal];
                    [cell.btnOrderStatus setImage:nil forState:UIControlStateNormal];
                } else {
                    [cell.btnOrderStatus setTitle:@"已激活" forState:UIControlStateNormal];
                    [cell.btnOrderStatus setImage:[UIImage imageNamed:@"order_actived"] forState:UIControlStateNormal];
                }
                [cell.btnOrderStatus setTitleColor:[UIColor colorWithRed:23/255.0 green:186/255.0 blue:34/255.0 alpha:1.0] forState:UIControlStateNormal];
                break;
            case 2:
                [cell.btnOrderStatus setTitle:@"已过期" forState:UIControlStateNormal];
                [cell.btnOrderStatus setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                [cell.btnOrderStatus setImage:[UIImage imageNamed:@"order_unactive"] forState:UIControlStateNormal];
                break;
            case 3:
                [cell.btnOrderStatus setTitle:@"已取消" forState:UIControlStateNormal];
                [cell.btnOrderStatus setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                [cell.btnOrderStatus setImage:[UIImage imageNamed:@"order_unactive"] forState:UIControlStateNormal];
                break;
            case 4:
                [cell.btnOrderStatus setTitle:@"激活失败" forState:UIControlStateNormal];
                [cell.btnOrderStatus setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                [cell.btnOrderStatus setImage:[UIImage imageNamed:@"order_unactive"] forState:UIControlStateNormal];
                break;
                
            default:
                [cell.btnOrderStatus setTitle:@"未知状态" forState:UIControlStateNormal];
                [cell.btnOrderStatus setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                [cell.btnOrderStatus setImage:[UIImage imageNamed:@"order_unactive"] forState:UIControlStateNormal];
                break;
        }
    }
    
    //    cell.btnOrderStatus.text = [dicOrder objectForKey:@"Operators"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dicOrder = [self.arrOrderData objectAtIndex:indexPath.row];
    ActivateGiftCardViewController *giftCardVC = [[ActivateGiftCardViewController alloc] init];
    giftCardVC.idOrder = dicOrder[@"OrderID"];
    [self.navigationController pushViewController:giftCardVC animated:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"actionOrderSuccess" object:@"actionOrderSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BuyConfrim" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundGiftCardSuccess" object:@"boundGiftCardSuccess"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
