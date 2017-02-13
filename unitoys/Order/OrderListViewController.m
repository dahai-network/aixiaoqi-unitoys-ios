//
//  OrderListViewController.m
//  unitoys
//
//  Created by sumars on 16/9/29.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "OrderListViewController.h"
#import "OrderCell.h"
#import "OrderDetailViewController.h"
#import "UIImageView+WebCache.h"
#import "BindGiftBagCardViewController.h"
#import "ActivateGiftCardViewController.h"
#import "CommunicatePackageViewController.h"


@interface OrderListViewController ()

@end

@implementation OrderListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    [self checkOrderList];
    //右边按钮
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mypackge_add"] style:UIBarButtonItemStyleDone target:self action:@selector(rightButtonAction)];
    self.navigationItem.rightBarButtonItem = right;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkOrderList) name:@"actionOrderSuccess" object:@"actionOrderSuccess"];//激活成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkOrderList) name:@"BuyConfrim" object:nil];//取消
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkOrderList) name:@"boundGiftCardSuccess" object:@"boundGiftCardSuccess"];//绑定礼包卡成功
    
    // Do any additional setup after loading the view.

}

- (void)rightButtonAction {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *firstAlertAction = [UIAlertAction actionWithTitle:@"通话套餐" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        CommunicatePackageViewController *communicateVC = [[CommunicatePackageViewController alloc] init];
        [self.navigationController pushViewController:communicateVC animated:YES];
    }];
    
    UIAlertAction *secondAlertAction = [UIAlertAction actionWithTitle:@"国际流量套餐" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
        UIViewController *countryListViewController = [mainStory instantiateViewControllerWithIdentifier:@"countryListViewController"];
        if (countryListViewController) {
            self.tabBarController.tabBar.hidden = YES;
            [self.navigationController pushViewController:countryListViewController animated:YES];
        }
    }];
    
    UIAlertAction *thirdAlertAction = [UIAlertAction actionWithTitle:@"绑定套餐礼包卡" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        BindGiftBagCardViewController *bindVC = [[BindGiftBagCardViewController alloc] init];
        [self.navigationController pushViewController:bindVC animated:YES];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:firstAlertAction];
    [alertController addAction:secondAlertAction];
    [alertController addAction:thirdAlertAction];
    //修改按钮文字颜色
    alertController.view.tintColor = [UIColor blackColor];
    [firstAlertAction setValue:[UIColor blueColor] forKey:@"titleTextColor"];
    [secondAlertAction setValue:[UIColor blueColor] forKey:@"titleTextColor"];
    [thirdAlertAction setValue:[UIColor blueColor] forKey:@"titleTextColor"];
    [self presentViewController:alertController animated:YES completion:nil];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrOrderData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OrderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OrderCell"];
    
    NSDictionary *dicOrder = [self.arrOrderData objectAtIndex:indexPath.row];
//    cell.ivLogoPic.image = [[UIImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[dicOrder objectForKey:@"LogoPic"]]]];
    [cell.ivLogoPic sd_setImageWithURL:[NSURL URLWithString:[dicOrder objectForKey:@"LogoPic"]]];
    cell.lblFlow.text = [dicOrder objectForKey:@"PackageName"];//[NSString stringWithFormat:@"流量:%dMB",[[dicOrder objectForKey:@"Flow"] intValue]/1024];
    cell.lblExpireDays.text = [dicOrder objectForKey:@"ExpireDays"];
    cell.lblTotalPrice.text = [NSString stringWithFormat:@"￥%.2f",[[dicOrder objectForKey:@"TotalPrice"] floatValue]];
    cell.lblTotalPrice.font = [UIFont systemFontOfSize:15 weight:2];
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

@end
