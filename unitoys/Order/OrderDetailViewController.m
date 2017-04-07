//
//  OrderDetailViewController.m
//  unitoys
//
//  Created by sumars on 16/9/29.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "OrderDetailViewController.h"
#import "OrderActivationViewController.h"

@interface OrderDetailViewController ()
@property (weak, nonatomic) IBOutlet BorderButton *actionButton;

@end

@implementation OrderDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self checkOrderInfo];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkOrderInfo) name:@"actionOrderSuccess" object:@"actionOrderSuccess"];
}

//- (void)viewWillAppear:(BOOL)animated {
//    
//}

- (void)checkOrderInfo {
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.idOrder,@"id", nil];
    
    [self getBasicHeader];
//    NSLog(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiOrderById params:params success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            self.dicOrderDetail = [responseObj objectForKey:@"data"];
            
            self.lblTotalPrice.text = [NSString stringWithFormat:@"￥%.2f",[[[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"TotalPrice"] floatValue]];
            self.lblPackageName.text = [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"PackageName"];
            self.ivLogoPic.image = [[UIImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"LogoPic"]]]];
            
            self.lblQuantity.text = [NSString stringWithFormat:@"x%d",[[[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"Quantity"] intValue]];
            
            self.btnOrderCancel.hidden = YES;
            
            switch ([[[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"OrderStatus"] intValue]) {
                case 0:
                    [_lblOrderStatus setText:INTERNATIONALSTRING(@"套餐状态：未激活")];
                    self.btnOrderCancel.hidden = NO;
                    break;
                case 1:
                    [_lblOrderStatus setText:INTERNATIONALSTRING(@"套餐状态：已激活")];
                    break;
                case 2:
                    [_lblOrderStatus setText:INTERNATIONALSTRING(@"套餐状态：已过期")];
                    break;
                case 3:
                    [_lblOrderStatus setText:INTERNATIONALSTRING(@"套餐状态：已取消")];
                    break;
                case 4:
                    [_lblOrderStatus setText:INTERNATIONALSTRING(@"套餐状态：激活失败")];
                    break;
                    
                default:
                    break;
            }
            
            self.lblExprieDay.text = [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"ExpireDays"];
            
            self.lblOrderNum.text = [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"OrderNum"];
            self.lblOrderDate.text = [self formatTime:[self convertDate:[[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"OrderDate"]]];
            if ([responseObj[@"data"][@"list"][@"OrderStatus"] isEqualToString:@"0"]) {
                [self.actionButton setTitle:INTERNATIONALSTRING(@"激活套餐") forState:UIControlStateNormal];
                self.actionButton.hidden = NO;
            } else if ([responseObj[@"data"][@"list"][@"OrderStatus"] isEqualToString:@"4"]) {
                [self.actionButton setTitle:INTERNATIONALSTRING(@"重新激活") forState:UIControlStateNormal];
                self.actionButton.hidden = NO;
            } else {
                self.actionButton.hidden = YES;
            }
            if ([responseObj[@"data"][@"list"][@"PaymentMethod"] intValue] == 1) {
                self.lblPaymentMethod.text = INTERNATIONALSTRING(@"支付宝支付");
            }else if ([responseObj[@"data"][@"list"][@"PaymentMethod"] intValue] == 2) {
                self.lblPaymentMethod.text = INTERNATIONALSTRING(@"微信支付");
            } else if ([responseObj[@"data"][@"list"][@"PaymentMethod"] intValue] == 3) {
                self.lblPaymentMethod.text = INTERNATIONALSTRING(@"余额支付");
            }
            
            self.lblOrderPrice.text = [NSString stringWithFormat:@"￥%.2f",[[[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"TotalPrice"] floatValue]];
            
            
            
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        NSLog(@"查询到的订单详情数据：%@",responseObj);
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


- (IBAction)orderAvation:(id)sender {
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
    OrderActivationViewController *orderActivationViewController = [mainStory instantiateViewControllerWithIdentifier:@"orderActivationViewController"];
    if (orderActivationViewController) {
        orderActivationViewController.dicOrderDetail = self.dicOrderDetail;
        [self.navigationController pushViewController:orderActivationViewController animated:YES];
    }

    /*
    OrderActivationViewController *orderActivationViewController = [mainStory instantiateViewControllerWithIdentifier:@"orderActivationViewController"];
    if (orderActivationViewController) {
        orderActivationViewController.dicOrderDetail = self.dicOrderDetail;
        [self.navigationController pushViewController:orderActivationViewController animated:YES];
    }*/
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 15;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (IBAction)orderCancel:(id)sender {
    [self dj_alertAction:self alertTitle:nil actionTitle:@"继续" message:@"您将要取消此订单" alertAction:^{
        [self cancelOrder];
    }];
}

- (void)cancelOrder {
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[self.dicOrderDetail[@"list"] objectForKey:@"OrderID"],@"OrderID", nil];
    
    [self getBasicHeader];
//    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiOrderCancel params:params success:^(id responseObj) {
        //
        //KV来存放数组，所以要用枚举器来处理
        /*
         NSEnumerator *enumerator = [[responseObj objectForKey:@"data"] keyEnumerator];
         id key;
         while ((key = [enumerator nextObject])) {
         [manager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
         }*/
        
        NSLog(@"查询到的用户数据：%@",responseObj);
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            //套餐取消完成
            //            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            HUDNormal(responseObj[@"msg"])
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BuyConfrim" object:nil];
            [self.navigationController popViewControllerAnimated:YES];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            //            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            HUDNormal(responseObj[@"msg"])
        }
        
        
        
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"actionOrderSuccess" object:@"actionOrderSuccess"];
}
@end
