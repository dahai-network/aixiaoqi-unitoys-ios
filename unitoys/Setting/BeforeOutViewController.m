//
//  BeforeOutViewController.m
//  unitoys
//
//  Created by sumars on 16/11/16.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BeforeOutViewController.h"
#import "OrderDetailViewController.h"
#import "CountryListViewController.h"

#import "OrderCell.h"

#import "UIImageView+WebCache.h"

@interface BeforeOutViewController ()

@end

@implementation BeforeOutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIButton *btnBuyPackage = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    [btnBuyPackage setTitle:INTERNATIONALSTRING(@"购买套餐") forState:UIControlStateNormal];
    [btnBuyPackage setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btnBuyPackage addTarget:self action:@selector(buyPackage) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:btnBuyPackage];
//    [self.navigationController.navigationItem setRightBarButtonItem:rightItem];
    
    [self.navigationItem setRightBarButtonItem:rightItem];
    
    [self loadPackages];
}

- (void)loadPackages {
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

- (void)buyPackage {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
    UIViewController *countryListViewController = [mainStory instantiateViewControllerWithIdentifier:@"countryListViewController"];
    if (countryListViewController) {
        self.tabBarController.tabBar.hidden = YES;
        [self.navigationController pushViewController:countryListViewController animated:YES];
    }
}

- (void)dealloc {
    [self.navigationController.navigationItem setRightBarButtonItem:nil];
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
//    cell.lblTotalPrice.text = [NSString stringWithFormat:@"￥%.2f",[[dicOrder objectForKey:@"TotalPrice"] floatValue]];
    if ([[dicOrder objectForKey:@"PayStatus"] intValue]==0) {
        NSLog(@"未支付");
    }else{
        //order_actived
        switch ([[dicOrder objectForKey:@"OrderStatus"] intValue]) {
            case 0:
                [cell.btnOrderStatus setTitle:INTERNATIONALSTRING(@"未激活") forState:UIControlStateNormal];
                [cell.btnOrderStatus setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                break;
            case 1:
                [cell.btnOrderStatus setTitle:INTERNATIONALSTRING(@"已激活") forState:UIControlStateNormal];
                [cell.btnOrderStatus setImage:[UIImage imageNamed:@"order_actived"] forState:UIControlStateNormal];
                break;
            case 2:
                [cell.btnOrderStatus setTitle:INTERNATIONALSTRING(@"已过期") forState:UIControlStateNormal];
                [cell.btnOrderStatus setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                break;
            case 3:
                [cell.btnOrderStatus setTitle:INTERNATIONALSTRING(@"已取消") forState:UIControlStateNormal];
                [cell.btnOrderStatus setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                break;
            case 4:
                [cell.btnOrderStatus setTitle:INTERNATIONALSTRING(@"激活失败") forState:UIControlStateNormal];
                [cell.btnOrderStatus setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                break;
                
            default:
                [cell.btnOrderStatus setTitle:INTERNATIONALSTRING(@"未知状态") forState:UIControlStateNormal];
                [cell.btnOrderStatus setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                break;
        }
    }
    
    //    cell.btnOrderStatus.text = [dicOrder objectForKey:@"Operators"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dicOrder = [self.arrOrderData objectAtIndex:indexPath.row];
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
    OrderDetailViewController *orderDetailViewController = [mainStory instantiateViewControllerWithIdentifier:@"orderDetailViewController"];
    if (orderDetailViewController) {
        orderDetailViewController.idOrder = [dicOrder objectForKey:@"OrderID"];
        [self.navigationController pushViewController:orderDetailViewController animated:YES];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return INTERNATIONALSTRING(@"已购套餐");
}

@end
