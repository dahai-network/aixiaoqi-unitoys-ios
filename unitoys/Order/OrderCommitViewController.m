//
//  OrderCommitViewController.m
//  unitoys
//
//  Created by sumars on 16/9/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "OrderCommitViewController.h"
#import <AlipaySDK/AlipaySDK.h>
#import "Order.h"
#import "DataSigner.h"
#import "WXApi.h"

#import "PaySuccessViewController.h"

@interface OrderCommitViewController ()
@property (nonatomic, copy)NSString *orderID;
@property (nonatomic, assign)int packageCategory;
@property (weak, nonatomic) IBOutlet UIButton *paymentButton;

@end

@implementation OrderCommitViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.orderCount = 1;
    
    if (self.dicPackage) {
        NSLog(@"套餐数据:%@",self.dicPackage);
        [self.ivPackagePic setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[self.dicPackage objectForKey:@"LogoPic"]]]]];
        self.lblPrice.text = [NSString stringWithFormat:@"￥%.2f",[[self.dicPackage objectForKey:@"Price"] floatValue]];
//        self.lblExpireDays.text = [NSString stringWithFormat:@"有效期：%@",[self.dicPackage objectForKey:@"ExpireDays"]];
        self.lblPackageName.text = [self.dicPackage objectForKey:@"PackageName"];
        
        self.lblOrderPrice.text = [NSString stringWithFormat:@"￥%.2f",[[self.dicPackage objectForKey:@"Price"] floatValue]];
        
        self.lblOrderCount.text = [NSString stringWithFormat:@"%ld",(long)self.orderCount];
        
        [self calcFee];

    }
    
    [self loadAmmount];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alipayComplete:) name:@"AlipayComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weipayComplete:) name:@"WeipayComplete" object:nil];
    // Do any additional setup after loading the view.
    
    self.arrMethod = [NSArray arrayWithObjects:self.btnAccountpay,self.btnWeipay,self.btnAlipay, nil];
    self.btnMethod = self.btnAccountpay;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 15;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 2) {
        return 15;
    } else {
        return 0.01;
    }
}

- (void) loadAmmount {
    self.checkToken = YES;
    
    [self getBasicHeader];
    //    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest getRequest:apiGetUserAmount params:nil success:^(id responseObj) {
        //
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            self.paymentButton.enabled = YES;
            self.ammountValue = [[[responseObj objectForKey:@"data"] objectForKey:@"amount"] floatValue];
            
            
            self.lblAmmountValue.text = [NSString stringWithFormat:@"%@(%@￥%.2f)", INTERNATIONALSTRING(@"余额支付"), INTERNATIONALSTRING(@"剩余"),[[[responseObj objectForKey:@"data"] objectForKey:@"amount"] floatValue]];
            
            if (self.ammountValue>self.totalFee){
                self.btnAccountpay.enabled = TRUE;
            }else{
                //不够支付
                self.btnAccountpay.enabled = FALSE;
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        //        NSLog(@"查询到的用户数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)alipayComplete: (NSNotification *)notification{
    
    NSDictionary *resultDic = notification.object;
    NSString *payResult = [resultDic objectForKey:@"result"];//notification.object;
   
    if ([payResult rangeOfString:[self.dicOrder objectForKey:@"OrderNum"]].location==NSNotFound) {
        //
    }else{
        /*
        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"X当前订单已支付完成！" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];*/
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
        if (storyboard) {
            PaySuccessViewController *paySuccessViewController = [storyboard instantiateViewControllerWithIdentifier:@"paySuccessViewController"];
            
            if (paySuccessViewController) {
                /*
                [paySuccessViewController.btnHintInfo setTitle:@"购买成功" forState:UIControlStateNormal];
                
                paySuccessViewController.lblPayMethod.text = @"支付宝";
                paySuccessViewController.lblPayAmount.text = [NSString stringWithFormat:@"￥%@",self.lblFactPayment.text];*/
                paySuccessViewController.strHintInfo = INTERNATIONALSTRING(@"充值成功");
                paySuccessViewController.strPayMethod = INTERNATIONALSTRING(@"支付宝");
                paySuccessViewController.strPayAmount = [NSString stringWithFormat:@"￥%@",self.lblOrderAmount.text];
                paySuccessViewController.title = INTERNATIONALSTRING(@"购买成功");
                paySuccessViewController.orderID = self.orderID;
                paySuccessViewController.packageCategory = self.packageCategory;
                [self.navigationController pushViewController:paySuccessViewController animated:YES];
                
            }
        }
    }
}

- (void)weipayComplete: (NSNotification *)notification{
    NSString *payResult = notification.object;
    
    
    NSString *weipayType = [[NSUserDefaults standardUserDefaults] objectForKey:@"WeipayType"];
    
    if ([weipayType isEqualToString:@"Order"]) {
        if ([payResult isEqualToString:@"success"]) {
            //
            /*
            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"X当前订单已支付完成！" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];*/
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
            if (storyboard) {
                PaySuccessViewController *paySuccessViewController = [storyboard instantiateViewControllerWithIdentifier:@"paySuccessViewController"];
                
                if (paySuccessViewController) {
                    /*
                    [paySuccessViewController.btnHintInfo setTitle:@"购买成功" forState:UIControlStateNormal];
                    
                    paySuccessViewController.lblPayMethod.text = @"微信支付";
                    paySuccessViewController.lblPayAmount.text = [NSString stringWithFormat:@"￥%@",_lblOrderAmount.text];*/
                    paySuccessViewController.strHintInfo = INTERNATIONALSTRING(@"充值成功");
                    paySuccessViewController.strPayMethod = INTERNATIONALSTRING(@"微信支付");
                    paySuccessViewController.strPayAmount = [NSString stringWithFormat:@"￥%@",self.lblOrderAmount.text];
                    paySuccessViewController.title = INTERNATIONALSTRING(@"购买成功");
                    paySuccessViewController.orderID = self.orderID;
                    paySuccessViewController.packageCategory = self.packageCategory;
                    
                    [self.navigationController pushViewController:paySuccessViewController animated:YES];
                    
                }
            }

        }else{
            if (payResult) {
                [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:payResult delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
            } else {
                [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:INTERNATIONALSTRING(@"支付失败，可能已取消支付或者其他原因") delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
            }
        }
    }
    
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.message isEqualToString:@"你当前订单已支付完成！"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }else if ([alertView.message isEqualToString:@"支付成功！"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)calcFee {
    if (self.dicPackage) {
        self.totalFee = self.orderCount * [[self.dicPackage objectForKey:@"Price"] floatValue];
        self.lblOrderAmount.text = [NSString stringWithFormat:@"￥%.2f",self.totalFee];
        
        
        self.lblFactPayment.text = [NSString stringWithFormat:@"￥%.2f",self.totalFee];
        self.lblOrderFee.text = [NSString stringWithFormat:@"￥%.2f",self.totalFee];
        
        if (self.ammountValue>self.totalFee){
            if (self.btnAccountpay.enabled == NO) {
                self.btnAccountpay.enabled = YES;
            }
        }else{
            //不够支付
            
            if (self.btnAccountpay.tag==1) {
                self.btnAccountpay.enabled = NO;
                [self switchPayment:self.btnAlipay];
            }else{
                self.btnAccountpay.enabled = NO;
            }
            /*
             self.btnAccountpay.tag = 0;
             self.btnAccountpay.enabled = FALSE;*/
        }
    }
    
//   self.lblOrderAmount.text
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

- (IBAction)decAmount:(id)sender {
    if (self.orderCount > 1) {
        self.orderCount = self.orderCount-1;
        
        self.lblOrderCount.text = [NSString stringWithFormat:@"%ld",(long)self.orderCount];
        
        [self calcFee];
    } else {
        HUDNormal(INTERNATIONALSTRING(@"已经不能再少了!"))
    }
    
}

- (IBAction)addAmount:(id)sender {
    
    self.orderCount = self.orderCount+1;
    
    self.lblOrderCount.text = [NSString stringWithFormat:@"%ld",(long)self.orderCount];
    
    [self calcFee];
    
}

- (IBAction)switchPayment:(id)sender {
    self.btnMethod = sender;
    
    
    for (UIButton *btn in self.arrMethod) {
        if ([btn isEqual:self.btnMethod]) {
            btn.tag=1;
            [btn setImage:[UIImage imageNamed:@"order_checked"] forState:UIControlStateNormal];
        } else {
            btn.tag=0;
            [btn setImage:[UIImage imageNamed:@"order_uncheck"] forState:UIControlStateNormal];
        }
    }
    /*
    if (_btnWeipay.tag==1) {
        self.btnAlipay.tag=1;
        [self.btnAlipay setImage:[UIImage imageNamed:@"order_checked"] forState:UIControlStateNormal];
        self.btnWeipay.tag=0;
        [self.btnWeipay setImage:[UIImage imageNamed:@"order_uncheck"] forState:UIControlStateNormal];
    } else {
        self.btnWeipay.tag=1;
        [self.btnWeipay setImage:[UIImage imageNamed:@"order_checked"] forState:UIControlStateNormal];
        self.btnAlipay.tag=0;
        [self.btnAlipay setImage:[UIImage imageNamed:@"order_uncheck"] forState:UIControlStateNormal];
    }*/
}

- (BOOL)commitOrder {
    self.checkToken = YES;
    //    ;
    //
    NSDictionary *params;
    
    
    if (self.btnAlipay.tag==1) {
        params = [[NSDictionary alloc] initWithObjectsAndKeys:[self.dicPackage objectForKey:@"PackageId"],@"PackageID",[NSString stringWithFormat:@"%ld", self.orderCount],@"Quantity",@"1",@"PaymentMethod", nil];
    } else if(self.btnWeipay.tag==1) {
        params = [[NSDictionary alloc] initWithObjectsAndKeys:[self.dicPackage objectForKey:@"PackageId"],@"PackageID",[NSString stringWithFormat:@"%ld", self.orderCount],@"Quantity",@"2",@"PaymentMethod", nil];
    } else {
        params = [[NSDictionary alloc] initWithObjectsAndKeys:[self.dicPackage objectForKey:@"PackageId"],@"PackageID",[NSString stringWithFormat:@"%ld", self.orderCount],@"Quantity",@"3",@"PaymentMethod", nil];
    }
    HUDNoStop1(INTERNATIONALSTRING(@"正在提交订单..."))
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    
    [SSNetworkRequest postRequest:apiOrderAdd params:params success:^(id responseObj) {
        NSLog(@"查询到的订单数据：%@",responseObj);
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            self.dicOrder = [[responseObj objectForKey:@"data"] objectForKey:@"order"];
            self.orderID = self.dicOrder[@"OrderID"];
            self.packageCategory = [self.dicOrder[@"PackageCategory"] intValue];
            [self payAction];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        
        /*
        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];*/
        
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        NSLog(@"啥都没：%@",[error description]);
        
    } headers:self.headers];
    return YES;
}


- (void)callbackOrder {
    self.checkToken = YES;
    //    ;
    //
    NSDictionary *params;
    
    
    
    params = [[NSDictionary alloc] initWithObjectsAndKeys:[self.dicPackage objectForKey:@"PackageId"],@"PackageID",[NSString stringWithFormat:@"%ld", self.orderCount],@"Quantity",@"1",@"PaymentMethod", nil];
    
    
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    
    [SSNetworkRequest postRequest:apiPayNotifyAnsync params:params success:^(id responseObj) {
        //
        //KV来存放数组，所以要用枚举器来处理
        /*
         NSEnumerator *enumerator = [[responseObj objectForKey:@"data"] keyEnumerator];
         id key;
         while ((key = [enumerator nextObject])) {
         [manager.requestSerializer setValue:[headers objectForKey:key] forHTTPHeaderField:key];
         }*/
        
        
        NSLog(@"查询到的订单数据：%@",responseObj);
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            self.dicOrder = [[responseObj objectForKey:@"data"] objectForKey:@"order"];
        
            [self payAction];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        
        /*
         [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];*/
        
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        NSLog(@"啥都没：%@",[error description]);
        
    } headers:self.headers];
    
}

- (void)payAction {
    if (self.btnAlipay.tag==1) {
        [self alipay];
    }else if(self.btnWeipay.tag==1){
        if ([self isWXAppInstalled]) {
            [self weipay];
        }
    }else{
        [self ammountpay];
    }
}

- (void)ammountpay {
    self.checkToken = YES;
    
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[self.dicOrder objectForKey:@"OrderID"],@"OrderID", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiPayOrderByUserAmount params:params success:^(id responseObj) {
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
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
            if (storyboard) {
                PaySuccessViewController *paySuccessViewController = [storyboard instantiateViewControllerWithIdentifier:@"paySuccessViewController"];
                
                if (paySuccessViewController) {
                    
                    paySuccessViewController.strHintInfo = INTERNATIONALSTRING(@"充值成功");
                    paySuccessViewController.strPayMethod = INTERNATIONALSTRING(@"余额支付");
                    paySuccessViewController.strPayAmount = [NSString stringWithFormat:@"%@",self.lblOrderAmount.text];
                    paySuccessViewController.title = INTERNATIONALSTRING(@"购买成功");
                    paySuccessViewController.orderID = self.orderID;
                    paySuccessViewController.packageCategory = self.packageCategory;
                    
                    
                    
                    
                    [self.navigationController pushViewController:paySuccessViewController animated:YES];
                    
                }
            }
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        }
        
        
        
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
    
}

- (IBAction)payment:(id)sender {
    [self commitOrder];
    
    /*
    if ([self commitOrder]) {
        if (self.btnAlipay.tag==1) {
            [self alipay];
        }else{
            [self weipay];
        }
    }
    */
    
}

- (void)weipay {
    self.checkToken = YES;
    
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[self.dicOrder objectForKey:@"OrderNum"],@"orderOrPayment", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiGetPrepayID params:params success:^(id responseObj) {
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
            NSMutableDictionary *dict = NULL;
            
            dict = [responseObj objectForKey:@"data"];
            
            if(dict != nil){
                NSMutableString *retcode = [dict objectForKey:@"retcode"];
                if (retcode.intValue == 0){
                    NSMutableString *stamp  = [dict objectForKey:@"timestamp"];
                    
                    //调起微信支付
                    PayReq* req             = [[PayReq alloc] init];
                    req.partnerId           = [dict objectForKey:@"partnerid"];
                    req.prepayId            = [dict objectForKey:@"prepayid"];
                    req.nonceStr            = [dict objectForKey:@"noncestr"];
                    req.timeStamp           = stamp.intValue;
                    req.package             = [dict objectForKey:@"package"];
                    req.sign                = [dict objectForKey:@"sign"];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:@"Order" forKey:@"WeipayType"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    [WXApi sendReq:req];
                    //日志输出
                    NSLog(@"appid=%@\npartid=%@\nprepayid=%@\nnoncestr=%@\ntimestamp=%ld\npackage=%@\nsign=%@",[dict objectForKey:@"appid"],req.partnerId,req.prepayId,req.nonceStr,(long)req.timeStamp,req.package,req.sign );
                    //                    return @"";
                }else{
                    //                    return [dict objectForKey:@"retmsg"];
                    NSLog(@"支付返回异常:%@",[dict objectForKey:@"retmsg"]);
                }
            }else{
                NSLog(@"服务器返回异常");
                //                return @"服务器返回错误，未获取到json对象";
            }
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        }
        

        
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
    
}

- (void)alipay {
    /*
     *商户的唯一的parnter和seller。
     *签约后，支付宝会为每个商户分配一个唯一的 parnter 和 seller。
     */
    
    /*============================================================================*/
    /*=======================需要填写商户app申请的===================================*/
    /*============================================================================*/
    NSString *appID =   @"2016081201740861";
    NSString *partner = @"2088421645383390";
    NSString *seller = @"13054445444@qq.com";
    NSString *privateKey =
    @"MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBAJU3u9F8d4jxw1jkRwGx2g9kOzP3Exv9U/lfxkaSuBuEWASLXI2cFdFkGOyD3mKMM5XTs9HYD4qLFXtaldyC2lY0fxb80F/vRU+3Oe8D9TH/CJ7p6SeTG8MfeIeWEK8VIQr6NnM7ywwECvpG8uElzfnGlUSB28cBMCqARYGlyWhfAgMBAAECgYBB+VJhXNa9BaeJNeTvKuNuyrIiV6trRKZMK7xOl7Au+mSwHa3eLpS277rVV7iLedGU/PUUYqL8bmIhF/wKcxB1QAaKpDpPv9SIAzfHLw+KuYv0JN3Ypvet+EtLKTO2k74oQGN/GTFp2mOtYKwfkU/lyO73HcgTUbVBcRL5iLIHAQJBAMadZPoQ5CF2A2OBp7cfCEeHmhtxk6QQBQ3cTRLC2ZZ9R8zgl3Hyqvx6/BT1muuu5DOmzUHmfSZR/BV9pVduQNcCQQDAVKq00NXmpqi0+esS9iozsvBNY6sS8q2r5EpyWdnzyLE8x/B0vjNoai6AW/t4m0aMGrXmfEaonCOeMjWuzTu5AkEAsfJAjx9lFWmjfZqjhhjClTuz4dSvf7Vuoc14LE/xHLigBLpQVaIiedVCVxD5vSFTicdvbRSxmgyoOyT4Z037vwJAIjErI/gYfufUCFCB5R4URJqkM+3rJPQ1weBVB91HbRqZv8d/zRFfTEnMOI+htkBMm23INtCTMziG8IHWn1vnKQJAbXasp5GarlCFiEYDaQVmR+JQAwFC6Xd5V1xwFcEpdkcIyvw8wkWObbKz0oWrMkKgHqpj8kQ2i+5eD/ECJXgy9w==";
    /*============================================================================*/
    /*============================================================================*/
    /*============================================================================*/
    
    //partner和seller获取失败,提示
    if ([partner length] == 0 ||
        [seller length] == 0 ||
        [privateKey length] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示")
                                                        message:INTERNATIONALSTRING(@"缺少partner或者seller或者私钥。")
                                                       delegate:self
                                              cancelButtonTitle:INTERNATIONALSTRING(@"确定")
                                              otherButtonTitles:nil];
        [alert show];
//        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    /*
     *生成订单信息及签名
     */
    //将商品信息赋予AlixPayOrder的成员变量
    Order* order = [Order new];
    
    // NOTE: app_id设置
    order.app_id = appID;
    
    // NOTE: 支付接口名称
    order.method = @"alipay.trade.app.pay";
    
    // NOTE: 参数编码格式
    order.charset = @"utf-8";
    
    // NOTE: 当前时间点
    NSDateFormatter* formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    order.timestamp = [formatter stringFromDate:[NSDate date]];
    
    // NOTE: 支付版本
    order.version = @"1.0";
    
    // NOTE: sign_type设置
    order.sign_type = @"RSA";
    
    // NOTE: 商品数据
    order.biz_content = [BizContent new];
    order.biz_content.body = [self.dicOrder objectForKey:@"PackageName"];
    order.biz_content.subject = @"套餐购买";
    order.biz_content.out_trade_no = [self.dicOrder objectForKey:@"OrderNum"]; //订单ID（由商家自行制定）
    order.biz_content.timeout_express = @"30m"; //超时时间设置
    order.biz_content.total_amount = [self.dicOrder objectForKey:@"TotalPrice"]; //商品价格
    
//    order.notify_url =  @"https://api.unitoys.com/api/AliPay/NotifyAsync";
    order.notify_url = apiAlipayNotify;
    
    //将商品信息拼接成字符串
    NSString *orderInfo = [order orderInfoEncoded:NO];
    NSString *orderInfoEncoded = [order orderInfoEncoded:YES];
    NSLog(@"orderSpec = %@",orderInfo);
    
    // NOTE: 获取私钥并将商户信息签名，外部商户的加签过程请务必放在服务端，防止公私钥数据泄露；
    //       需要遵循RSA签名规范，并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(privateKey);
    NSString *signedString = [signer signString:orderInfo];
    
    // NOTE: 如果加签成功，则继续执行支付
    if (signedString != nil) {
        //应用注册scheme,在AliSDKDemo-Info.plist定义URL types
        NSString *appScheme = @"unitoys";
        
        // NOTE: 将签名成功字符串格式化为订单字符串,请严格按照该格式
        NSString *orderString = [NSString stringWithFormat:@"%@&sign=%@",
                                 orderInfoEncoded, signedString];
        
        // NOTE: 调用支付结果开始支付
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"reslut = %@",resultDic);
        }];
    }
    
    

//     *生成订单信息及签名
/*
    Order *order = [[Order alloc] init];
    order.partner = partner;
    order.sellerID = seller;

    order.outTradeNO = [self.dicOrder objectForKey:@"OrderNum"];
    order.subject = @"套餐购买";
    order.body = [self.dicOrder objectForKey:@"PackageName"];
    order.totalFee = [self.dicOrder objectForKey:@"TotalPrice"];
    
    order.notifyURL =  @"https://api.unitoys.com/api/AliPay/NotifyAsync"; //回调URL
    
    order.service = @"mobile.securitypay.pay";
    order.paymentType = @"1";
    order.inputCharset = @"utf-8";
    order.itBPay = @"30m";
    order.showURL = @"m.alipay.com";
    
    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *appScheme = @"unitoys";
    
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    NSLog(@"orderSpec = %@",orderSpec);
    
    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(privateKey);
    NSString *signedString = [signer signString:orderSpec];
    
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                       orderSpec, signedString, @"RSA"];
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"reslut = %@",resultDic);
        }];
    }
 */
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
