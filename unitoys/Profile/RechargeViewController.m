//
//  RechargeViewController.m
//  unitoys
//
//  Created by sumars on 16/10/2.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "RechargeViewController.h"
#import <AlipaySDK/AlipaySDK.h>
#import "Order.h"
#import "DataSigner.h"
#import "BindChargeCardViewController.h"
#import "PaySuccessViewController.h"

#import "WXApi.h"

@interface RechargeViewController ()<UITextFieldDelegate, UITableViewDelegate>

@property (nonatomic, strong) UIButton *currentSelectButton;

@end

@implementation RechargeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edtRechargeValue.delegate = self;
    self.tableView.delegate = self;
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alipayComplete:) name:@"AlipayComplete" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weipayComplete:) name:@"WeipayComplete" object:nil];
    // Do any additional setup after loading the view.
    
    self.arrValues = [[NSArray alloc] initWithObjects:_btn20,_btn50,_btn100,_btn300,_btn500, nil];
    
    self.btnSelected = _btn20;
    self.currentSelectButton = self.btnAlipay;
    
}

- (IBAction)useChargeCard:(UIButton *)sender {
    BindChargeCardViewController *bindVC = [[BindChargeCardViewController alloc] init];
    [self.navigationController pushViewController:bindVC animated:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL isHaveDian = YES;
    if ([textField.text rangeOfString:@"."].location == NSNotFound) {
        isHaveDian = NO;
    }
    if ([string length] > 0) {
        unichar single = [string characterAtIndex:0];//当前输入的字符
        if ((single >= '0' && single <= '9') || single == '.') {//数据格式正确
            //首字母不能为小数点
            if([textField.text length] == 0){
                if(single == '.') {
//                    HUDNormal(@"亲，第一个数字不能为小数点")
                    [textField.text stringByReplacingCharactersInRange:range withString:@""];
                    return NO;
                }
            }
            if (textField.text.length == 1) {
                if ([textField.text isEqualToString:@"0"]) {
                    if (single != '.') {
//                        HUDNormal(@"不能输入两个0")
                        [textField.text stringByReplacingCharactersInRange:range withString:@""];
                        return NO;
                    }
                }
            }
            
            //输入的字符是否是小数点
            if (single == '.') {
                if(!isHaveDian)//text中还没有小数点
                {
//                    isHaveDian = YES;
                    return YES;
                    
                }else{
//                    HUDNormal(@"亲，您已经输入过小数点了")
                    [textField.text stringByReplacingCharactersInRange:range withString:@""];
                    return NO;
                }
            }else{
                if (isHaveDian) {//存在小数点
                    
                    //判断小数点的位数
                    NSRange ran = [textField.text rangeOfString:@"."];
                    if (range.location - ran.location <= 2) {
                        return YES;
                    }else{
                        HUDNormal(INTERNATIONALSTRING(@"亲，您最多输入两位小数"))
                        return NO;
                    }
                }else{
                    if (textField.text.length == 4) {
                        [textField.text stringByReplacingCharactersInRange:range withString:@""];
                        return NO;
                    } else {
                        return YES;
                    }
                }
            }
        }else{//输入的数据格式不正确
            HUDNormal(INTERNATIONALSTRING(@"亲，您输入的格式不正确"))
            [textField.text stringByReplacingCharactersInRange:range withString:@""];
            return NO;
        }
    }
    else
    {
        return YES;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.edtRechargeValue resignFirstResponder];
    return YES;
}

- (IBAction)changeValue:(id)sender {
    
    [self.edtRechargeValue resignFirstResponder];
    self.edtRechargeValue.text = @"";
    
    for (UIButton *btn in self.arrValues) {
        if ([btn isEqual:sender]) {
//            [btn setBackgroundImage:[UIImage imageNamed:@"pay_valueselected"] forState:UIControlStateNormal];
            [btn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
            [btn setBackgroundColor:UIColorFromRGB(0xf62a2a)];
            self.btnSelected = sender;
        } else {
//            [btn setBackgroundImage:[UIImage imageNamed:@"pay_valuenormal"] forState:UIControlStateNormal];
            [btn setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
            [btn setBackgroundColor:UIColorFromRGB(0xeeeeee)];
        }
    }
}

- (IBAction)inputValue:(id)sender {
    
    if(self.btnSelected){
//        [self.btnSelected setBackgroundImage:[UIImage imageNamed:@"pay_valuenormal"] forState:UIControlStateNormal];
        [self.btnSelected setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
        [self.btnSelected setBackgroundColor:UIColorFromRGB(0xeeeeee)];
        self.btnSelected = nil;
        
    }
    
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)alipayComplete: (NSNotification *)notification{
    NSDictionary *resultDic = notification.object;
    NSString *payResult = [resultDic objectForKey:@"result"];//notification.object;
    
    if ([payResult rangeOfString:self.orderNumber].location==NSNotFound) {
        //
    }else{
        /*
        [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"你当前订单已支付完成！" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];*/
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
        if (storyboard) {
            PaySuccessViewController *paySuccessViewController = [storyboard instantiateViewControllerWithIdentifier:@"paySuccessViewController"];
            
            if (paySuccessViewController) {
                /*
                [paySuccessViewController.btnHintInfo setTitle:@"充值成功" forState:UIControlStateNormal];
                
                paySuccessViewController.lblPayMethod.text = @"支付宝";
                paySuccessViewController.lblPayAmount.text = [NSString stringWithFormat:@"￥%@",self.edtRechargeValue.text];*/
                paySuccessViewController.strHintInfo = INTERNATIONALSTRING(@"充值成功");
                paySuccessViewController.strPayMethod = INTERNATIONALSTRING(@"支付宝");
                paySuccessViewController.strPayAmount = [NSString stringWithFormat:@"￥%@",self.payValue];
                paySuccessViewController.title = INTERNATIONALSTRING(@"充值成功");
                [self.navigationController pushViewController:paySuccessViewController animated:YES];
                
            }
        }
    }
}

- (void)weipayComplete: (NSNotification *)notification{
    NSString *payResult = notification.object;
    
    
    NSString *weipayType = [[NSUserDefaults standardUserDefaults] objectForKey:@"WeipayType"];
    
    if ([weipayType isEqualToString:@"Recharge"]) {
        if ([payResult isEqualToString:@"success"]) {
            //
            /*
            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"X当前订单已支付完成！" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];*/
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
            if (storyboard) {
                PaySuccessViewController *paySuccessViewController = [storyboard instantiateViewControllerWithIdentifier:@"paySuccessViewController"];
                
                if (paySuccessViewController) {
                    /*
                    [paySuccessViewController.btnHintInfo setTitle:@"充值成功" forState:UIControlStateNormal];
                    
                    paySuccessViewController.lblPayMethod.text = @"微信支付";
                    paySuccessViewController.lblPayAmount.text = [NSString stringWithFormat:@"￥%@",self.edtRechargeValue.text];*/
                    paySuccessViewController.strHintInfo = INTERNATIONALSTRING(@"充值成功");
                    paySuccessViewController.strPayMethod = INTERNATIONALSTRING(@"微信支付");
                    paySuccessViewController.strPayAmount = [NSString stringWithFormat:@"￥%@",self.payValue];
                    paySuccessViewController.title = INTERNATIONALSTRING(@"充值成功");
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    if (section == 1) {
//        return 15;
//    } else {
//        return 0.01;
//    }
    return 0.01;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
//                [self.btnAlipay setImage:[UIImage imageNamed:@"order_uncheck"] forState:UIControlStateNormal];
//                [self.btnWeipay setImage:[UIImage imageNamed:@"order_checked"] forState:UIControlStateNormal];
//                self.currentSelectButton = self.btnWeipay;
                [self switchPayment:self.btnWeipay];
                break;
            case 1:
//                [self.btnWeipay setImage:[UIImage imageNamed:@"order_uncheck"] forState:UIControlStateNormal];
//                [self.btnAlipay setImage:[UIImage imageNamed:@"order_checked"] forState:UIControlStateNormal];
//                self.currentSelectButton = self.btnAlipay;
                [self switchPayment:self.btnAlipay];
                break;
            default:
                break;
        }
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.message isEqualToString:INTERNATIONALSTRING(@"你当前订单已支付完成！")]) {
        [self.navigationController popViewControllerAnimated:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NeedRefreshAmount" object:nil];
    }
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

- (IBAction)switchPayment:(UIButton *)sender {

    if (sender == self.currentSelectButton) {
        return;
    }
    [self.currentSelectButton setImage:[UIImage imageNamed:@"order_uncheck"] forState:UIControlStateNormal];
    [sender setImage:[UIImage imageNamed:@"order_checked"] forState:UIControlStateNormal];
    self.currentSelectButton = sender;
    
//    if (_btnWeipay.tag==1) {
//        self.btnAlipay.tag=1;
//        [self.btnAlipay setImage:[UIImage imageNamed:@"order_checked"] forState:UIControlStateNormal];
//        self.btnWeipay.tag=0;
//        [self.btnWeipay setImage:[UIImage imageNamed:@"order_uncheck"] forState:UIControlStateNormal];
//    } else {
//        self.btnWeipay.tag=1;
//        [self.btnWeipay setImage:[UIImage imageNamed:@"order_checked"] forState:UIControlStateNormal];
//        self.btnAlipay.tag=0;
//        [self.btnAlipay setImage:[UIImage imageNamed:@"order_uncheck"] forState:UIControlStateNormal];
//    }
}

- (IBAction)payment:(id)sender {
    self.checkToken = YES;
    //    ;
    //
    
    NSString *paymentMethod;
    if (self.btnAlipay == self.currentSelectButton) {
        paymentMethod = @"1";
    }else{
        paymentMethod = @"2";
    }
    
    
    if (self.btnSelected) {
        self.payValue = _btnSelected.titleLabel.text;
    }else{
        if(self.edtRechargeValue.text.length>0){
            self.payValue = _edtRechargeValue.text;
        }else{
            HUDNormal(@"请输入充值金额")
            return;
        }
    }
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:paymentMethod,@"PaymentMethod",self.payValue,@"Amount", nil];
    
    [self getBasicHeader];
//    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiRecharge params:params success:^(id responseObj) {
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
            self.orderNumber = [[[responseObj objectForKey:@"data"] objectForKey:@"payment"] objectForKey:@"PaymentNum"];
            self.orderAmount =[NSString stringWithFormat:@"%.2f", [[[[responseObj objectForKey:@"data"] objectForKey:@"payment"] objectForKey:@"Amount"] floatValue]];
            
            if (self.btnAlipay == self.currentSelectButton) {
                
                [self alipay];
            }else{
                if ([self isWXAppInstalled]) {
                  [self weipay];
                }
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            [[[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"系统提示") message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:INTERNATIONALSTRING(@"确定") otherButtonTitles:nil, nil] show];
        }
        
        
        
        
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
    
    
    
}


- (void)weipay{
    self.checkToken = YES;

    
//    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.orderNumber,@"orderOrPayment", nil];
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:self.orderNumber,@"orderOrPayment", nil];
    
    [self getBasicHeader];
//    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiGetPrepayID params:info success:^(id responseObj) {
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
                    
                    [[NSUserDefaults standardUserDefaults] setObject:@"Recharge" forKey:@"WeipayType"];
                    
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
        //
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
    NSString *appID = @"2016081201740861";
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
        [privateKey length] == 0||
        [appID length] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"提示")
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
    order.version = @"2.0";
    
    // NOTE: sign_type设置
    order.sign_type = @"RSA";
    
    // NOTE: 商品数据
    order.biz_content = [BizContent new];
    order.biz_content.body = INTERNATIONALSTRING(@"账户余额充值");
    order.biz_content.subject = INTERNATIONALSTRING(@"账户充值");
    order.biz_content.out_trade_no = self.orderNumber; //订单ID（由商家自行制定）
    order.biz_content.timeout_express = @"30m"; //超时时间设置
    order.biz_content.total_amount = self.orderAmount; //商品价格
    
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
    
    /*
     signedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)signedString, NULL, (CFStringRef)@"!*'();:@&=+ $,./?%#[]", kCFStringEncodingUTF8));*/
    
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
    
    /*
    //将商品信息赋予AlixPayOrder的成员变量
    Order *order = [[Order alloc] init];
    order.partner = partner;
    order.sellerID = seller;
    order.appID = @"2016081201740861";
    
//    order.method = @"alipay.trade.app.pay";
    
//    order.bizContent = @"bizData";
    
    order.outTradeNO = self.orderNumber;
    order.subject = @"账户充值";
    order.body = @"账户余额充值";
    order.totalFee = self.orderAmount;
    
    
    order.service = @"mobile.securitypay.pay";
    order.paymentType = @"1";
    
    order.inputCharset = @"utf-8";
    order.itBPay = @"30m";
    order.showURL = @"m.alipay.com";
    
    order.notifyURL =  @"https://api.unitoys.com/api/AliPay/NotifyAsync"; //回调URL
    
    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *appScheme = @"unitoys";
    
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    NSLog(@"orderSpec = %@",orderSpec);
    
    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(privateKey);
    NSString *signedString = [signer signString:orderSpec];
    
    
//    NSString *uncodeString = @"timestamp=2016-10-10 22:42:45&biz_content={\"timeout_express\":\"30m\",\"product_code\":\"QUICK_MSECURITY_PAY\",\"total_amount\":\"0.01\",\"subject\":\"充值0.01\",\"body\":\"充值0.01\",\"out_trade_no\":\"9022201610102242458848845\"}&sign_type=RSA&notify_url=https://api.unitoys.com/api/AliPay/NotifyAsync&charset=utf-8&method=alipay.trade.app.pay&app_id=2016081201740861&version=1.0";
    
//    NSString *codedString = [signer signString:uncodeString];
    
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                       orderSpec, signedString, @"RSA"];
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"Fucker");
            NSLog(@"reslut = %@",resultDic);
        }];
    }*/
    //    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}



@end
