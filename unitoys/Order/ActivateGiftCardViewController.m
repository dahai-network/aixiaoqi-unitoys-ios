//
//  ActivateGiftCardViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/1/4.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ActivateGiftCardViewController.h"
#import "ActivateGiftCardTableViewCell.h"
#import "OrderActivationViewController.h"
#import "PackageDetailViewController.h"
#import "AbroadPackageExplainController.h"
#import "UNDatabaseTools.h"
#import "BlueToothDataManager.h"
#import "CommunicateDetailViewController.h"

@interface ActivateGiftCardViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UIView *footView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong)ActivateGiftCardTableViewCell *firstCell;
@property (nonatomic, strong)ActivateGiftCardTableViewCell *secondCell;
@property (nonatomic, strong)ActivateGiftCardTableViewCell *thirdCell;
@property (nonatomic, strong)CommunicateDetailViewController *communicateDetailVC;
@property (nonatomic, strong)NSDictionary *dicOrderDetail;
@property (weak, nonatomic) IBOutlet UIButton *activateButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (nonatomic, copy) NSString *packageId;
@property (nonatomic, copy) NSString *packageName;

//是否支持4G
@property (nonatomic, assign) NSNumber *IsSupport4G;
//是否需要APN
@property (nonatomic, assign) NSNumber *IsApn;
//APN证书名称
@property (nonatomic, copy)NSString *apnName;
@end

@implementation ActivateGiftCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.isAbroadMessage) {
        self.title = INTERNATIONALSTRING(@"已购套餐详情");
    }else{
        self.title = INTERNATIONALSTRING(@"套餐详情");
    }
    
    if (self.packageCategory != 2 && self.packageCategory != 3) {
        [self setRightButton:INTERNATIONALSTRING(@"使用教程")];
    }
    
//    self.packageCategory = 4;
    self.dicOrderDetail = [[NSDictionary alloc] init];

    self.tableView.tableFooterView = self.footView;
    //cell高度自适应
    self.tableView.estimatedRowHeight = 44.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.allowsSelection = YES;
    [self cehckOrderInfo];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cehckOrderInfo) name:@"actionOrderSuccess" object:@"actionOrderSuccess"];
    // Do any additional setup after loading the view from its nib.
}

- (void)leftButtonAction {
    if (self.isPaySuccess) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.isPaySuccess) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    self.isPaySuccess = YES;
}


#pragma mark 获取大王卡信息
- (void)cehckOrderInfo {
    HUDNoStop1(INTERNATIONALSTRING(@"正在加载..."))
    self.checkToken = YES;
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.idOrder,@"id", nil];
    NSString *apiNameStr = [NSString stringWithFormat:@"%@OrderId%@", @"apiOrderById", [self.idOrder stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    [self getBasicHeader];
    NSLog(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiOrderById params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            
            self.dicOrderDetail = [responseObj objectForKey:@"data"];
            self.packageCategory = [[self.dicOrderDetail[@"list"] objectForKey:@"PackageCategory"] intValue];
            setImage(self.firstCell.imgOrderView, [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"LogoPic"])
            self.packageId = responseObj[@"data"][@"list"][@"PackageId"];
            self.packageName = responseObj[@"data"][@"list"][@"PackageName"];
            self.IsSupport4G = responseObj[@"data"][@"list"][@"PackageIsSupport4G"];
            self.IsApn = responseObj[@"data"][@"list"][@"PackageIsApn"];
            self.firstCell.lblOrderName.text = responseObj[@"data"][@"list"][@"PackageName"];
            self.firstCell.lblOrderPrice.text = [NSString stringWithFormat:@"￥%@", responseObj[@"data"][@"list"][@"UnitPrice"]];
            self.apnName = responseObj[@"data"][@"list"][@"PackageApnName"];
            [self.tableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
    } failure:^(id dataObj, NSError *error) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            self.dicOrderDetail = [responseObj objectForKey:@"data"];
            self.packageCategory = [[self.dicOrderDetail[@"list"] objectForKey:@"PackageCategory"] intValue];
            setImage(self.firstCell.imgOrderView, [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"LogoPic"])
            self.packageId = responseObj[@"data"][@"list"][@"PackageId"];
            self.packageName = responseObj[@"data"][@"list"][@"PackageName"];
            self.IsSupport4G = responseObj[@"data"][@"list"][@"PackageIsSupport4G"];
            self.IsApn = responseObj[@"data"][@"list"][@"PackageIsApn"];
            self.firstCell.lblOrderName.text = responseObj[@"data"][@"list"][@"PackageName"];
            self.firstCell.lblOrderPrice.text = [NSString stringWithFormat:@"￥%@", responseObj[@"data"][@"list"][@"UnitPrice"]];
            self.apnName = responseObj[@"data"][@"list"][@"PackageApnName"];
            [self.tableView reloadData];
        }else{
            HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        }
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)rightButtonClick
{
    NSLog(@"使用教程");
    self.isPaySuccess = NO;
    AbroadPackageExplainController *abroadVc = [[AbroadPackageExplainController alloc] init];
    abroadVc.isSupport4G = [self.IsSupport4G boolValue];
    abroadVc.isApn = [self.IsApn boolValue];
    abroadVc.apnName = self.apnName;
    [self .navigationController pushViewController:abroadVc animated:YES];
}

#pragma mark - tableView代理方法
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 15;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.01;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (self.packageCategory == 0) {
        return 4;
    }else {
        return 3;
    }
}

//0流量/1通话/2大王卡/3双卡双待
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    //0流量/1通话/2大王卡/3双卡双待
    if (self.packageCategory == 0) {
        switch (section) {
            case 0:
                return 1;
                break;
            case 1:
                return 2;
                break;
            case 2:
                return 2;
                break;
            default:
                return 3;
                break;
        }
    } else if (self.packageCategory == 1) {
        switch (section) {
            case 0:
                return 1;
                break;
            case 1:
                return 2;
                break;
            default:
                return 3;
                break;
        }
    } else if (self.packageCategory == 2 || self.packageCategory == 3) {
        switch (section) {
            case 0:
                return 1;
                break;
            case 1:
                return 2;
                break;
            default:
                return 1;
                break;
        }
    } else {
        switch (section) {
            case 0:
                return 1;
                break;
            case 1:
                return 2;
                break;
            default:
                return 1;
                break;
        }
    }
}

//0流量/1通话/2大王卡/3双卡双待
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier1=@"ActivateGiftCardFirst";
    static NSString *identifier2=@"ActivateGiftCardSecond";
    static NSString *identifier3=@"ActivateGiftCardThird";
    switch (indexPath.section) {
        case 0:
            self.firstCell = [tableView dequeueReusableCellWithIdentifier:identifier1];
            if (!self.firstCell) {
                self.firstCell=[[[NSBundle mainBundle] loadNibNamed:@"ActivateGiftCardTableViewCell" owner:nil options:nil] firstObject];
            }
            
            if (self.packageCategory == 2 || self.packageCategory == 3) {
                self.firstCell.accessoryType = UITableViewCellAccessoryNone;
            }else{
                self.firstCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            return self.firstCell;
            break;
        case 1:
            self.secondCell = [tableView dequeueReusableCellWithIdentifier:identifier2];
            if (!self.secondCell) {
                self.secondCell=[[NSBundle mainBundle] loadNibNamed:@"ActivateGiftCardTableViewCell" owner:nil options:nil][1];
            }
            if (self.packageCategory == 2 || self.packageCategory == 3) {
                if (indexPath.row == 0) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"最晚激活日期");
                    self.secondCell.lblContent.text = [self convertDateWithString:self.dicOrderDetail[@"list"][@"LastCanActivationDate"]];
                } else if (indexPath.row == 1) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"套餐状态");
                    [self checkStatueWithLabel:self.secondCell.lblContent Statue:[[[self.dicOrderDetail objectForKey:@"list"] objectForKey:@"OrderStatus"] intValue]];
                } else {
                    NSLog(@"又出问题了");
                }
            } else {
                if (indexPath.row == 0) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"订单编号");
                    self.secondCell.lblContent.text = self.dicOrderDetail[@"list"][@"OrderNum"];
                } else if (indexPath.row == 1) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"支付时间");
                    self.secondCell.lblContent.text = [self convertDateWithString:self.dicOrderDetail[@"list"][@"PayDate"]];
                } else {
                    NSLog(@"又出问题了");
                }
            }
            return self.secondCell;
            break;
        case 2:
            if (self.packageCategory == 0) {
                self.secondCell = [tableView dequeueReusableCellWithIdentifier:identifier2];
                if (!self.secondCell) {
                    self.secondCell=[[NSBundle mainBundle] loadNibNamed:@"ActivateGiftCardTableViewCell" owner:nil options:nil][1];
                }
                if (indexPath.row == 0) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"支付方式");
                    self.secondCell.lblContent.text = [self checkPaymentModelWithPayment:self.dicOrderDetail[@"list"][@"PaymentMethod"]];
                } else if (indexPath.row == 1) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"总价");
                    self.secondCell.lblContent.text = [NSString stringWithFormat:@"￥%@", self.dicOrderDetail[@"list"][@"TotalPrice"]];
                } else {
                    NSLog(@"又出问题了");
                }
                return self.secondCell;
            } else if (self.packageCategory == 1) {
                self.secondCell = [tableView dequeueReusableCellWithIdentifier:identifier2];
                if (!self.secondCell) {
                    self.secondCell=[[NSBundle mainBundle] loadNibNamed:@"ActivateGiftCardTableViewCell" owner:nil options:nil][1];
                }
                if (indexPath.row == 0) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"支付方式");
                    self.secondCell.lblContent.text = [self checkPaymentModelWithPayment:self.dicOrderDetail[@"list"][@"PaymentMethod"]];
                } else if (indexPath.row == 1) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"有效期");
                    self.secondCell.lblContent.text = self.dicOrderDetail[@"list"][@"ExpireDays"];
                } else {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"套餐状态");
                    [self checkStatueWithLabel:self.secondCell.lblContent Statue:[[[self.dicOrderDetail objectForKey:@"list"] objectForKey:@"OrderStatus"] intValue]];
                }
                return self.secondCell;
            } else if (self.packageCategory == 2 || self.packageCategory == 3) {
                self.thirdCell = [tableView dequeueReusableCellWithIdentifier:identifier3];
                if (!self.thirdCell) {
                    self.thirdCell=[[NSBundle mainBundle] loadNibNamed:@"ActivateGiftCardTableViewCell" owner:nil options:nil][2];
                }
                self.thirdCell.lblIntroduceFirst.text = self.dicOrderDetail[@"list"][@"PackageFeatures"];
                self.thirdCell.lblIntroduceSecond.text = self.dicOrderDetail[@"list"][@"PackageDetails"];
                return self.thirdCell;
            } else {
                self.secondCell = [tableView dequeueReusableCellWithIdentifier:identifier2];
                if (!self.secondCell) {
                    self.secondCell=[[NSBundle mainBundle] loadNibNamed:@"ActivateGiftCardTableViewCell" owner:nil options:nil][1];
                }
                if (indexPath.row == 0) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"支付方式");
                    self.secondCell.lblContent.text = [self checkPaymentModelWithPayment:self.dicOrderDetail[@"list"][@"PaymentMethod"]];
                } else if (indexPath.row == 1) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"总价");
                    self.secondCell.lblContent.text = self.dicOrderDetail[@"list"][@"TotalPrice"];
                } else {
                    NSLog(@"又出问题了");
                }
                return self.secondCell;
            }
            break;
        default:
            self.secondCell = [tableView dequeueReusableCellWithIdentifier:identifier2];
            if (!self.secondCell) {
                self.secondCell=[[NSBundle mainBundle] loadNibNamed:@"ActivateGiftCardTableViewCell" owner:nil options:nil][1];
            }
            if (indexPath.row == 0) {
                self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"有效期");
                self.secondCell.lblContent.text = self.dicOrderDetail[@"list"][@"ExpireDays"];
            } else if (indexPath.row == 1) {
                self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"最晚激活日期");
                self.secondCell.lblContent.text = [self convertDateWithString:self.dicOrderDetail[@"list"][@"LastCanActivationDate"]];
            } else {
                self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"套餐状态");
                [self checkStatueWithLabel:self.secondCell.lblContent Statue:[[[self.dicOrderDetail objectForKey:@"list"] objectForKey:@"OrderStatus"] intValue]];
            }
            return self.secondCell;
            break;
    }
}

//0流量/1通话/2大王卡/3双卡双待
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
        PackageDetailViewController *packageDetailViewController = [mainStory instantiateViewControllerWithIdentifier:@"packageDetailViewController"];
        switch (self.packageCategory) {
            case 0:
                if (packageDetailViewController) {
                    packageDetailViewController.isAbroadMessage = YES;
                    packageDetailViewController.idPackage = self.packageId;
                    packageDetailViewController.currentTitle = self.packageName;
                    packageDetailViewController.isSupport4G = [self.IsSupport4G boolValue];
                    packageDetailViewController.isApn = [self.IsApn boolValue];
                    [self.navigationController pushViewController:packageDetailViewController animated:YES];
                }
                break;
            case 1:
                self.communicateDetailVC = [[CommunicateDetailViewController alloc] init];
                self.communicateDetailVC.communicateDetailID = self.packageId;
                [self.navigationController pushViewController:self.communicateDetailVC animated:YES];
                break;
            case 2:
                NSLog(@"大王卡套餐");
                break;
            case 3:
                NSLog(@"双卡双待套餐");
                break;
            default:
                break;
        }
        
    }
}

#pragma mark 根据不同状态显示不同文字
- (void)checkStatueWithLabel:(UILabel *)label Statue:(int)stastu {
    switch (stastu) {
        case 0:
            [label setText:INTERNATIONALSTRING(@"未激活")];
            self.activateButton.hidden = NO;
            if (self.packageCategory == 2) {
                self.cancelButton.hidden = YES;
            } else {
                self.cancelButton.hidden = NO;
            }
            break;
        case 1:
            if (self.packageCategory == 1) {
                label.text = [NSString stringWithFormat:@"%@ %@ %@", INTERNATIONALSTRING(@"剩余"), self.dicOrderDetail[@"list"][@"RemainingCallMinutes"], INTERNATIONALSTRING(@"分钟")];
            } else {
                [label setText:INTERNATIONALSTRING(@"已激活")];
            }
            label.textColor = [UIColor orangeColor];
            if (self.packageCategory == 0) {
                [self.activateButton setTitle:INTERNATIONALSTRING(@"立即激活") forState:UIControlStateNormal];
                self.activateButton.hidden = NO;
                self.cancelButton.hidden = YES;
            } else {
                self.activateButton.hidden = YES;
                self.cancelButton.hidden = YES;
            }
            break;
        case 2:
            [label setText:INTERNATIONALSTRING(@"已过期")];
            self.activateButton.hidden = YES;
            self.cancelButton.hidden = YES;
            break;
        case 3:
            [label setText:INTERNATIONALSTRING(@"已取消")];
            self.activateButton.hidden = YES;
            self.cancelButton.hidden = YES;
            break;
        case 4:
            [label setText:INTERNATIONALSTRING(@"激活失败")];
            [self.activateButton setTitle:INTERNATIONALSTRING(@"重新激活") forState:UIControlStateNormal];
            self.activateButton.hidden = NO;
            self.cancelButton.hidden = YES;
            break;
            
        default:
            break;
    }
}

#pragma mark 根据不同状态显示不同的支付方式 1.支付宝 2.微信 3.余额 4.官方赠送
- (NSString *)checkPaymentModelWithPayment:(NSString *)payment {
    NSString *paymentString;
    switch ([payment intValue]) {
        case 1:
            paymentString = INTERNATIONALSTRING(@"支付宝支付");
            break;
        case 2:
            paymentString = INTERNATIONALSTRING(@"微信支付");
            break;
        case 3:
            paymentString = INTERNATIONALSTRING(@"余额支付");
            break;
        case 4:
            paymentString = INTERNATIONALSTRING(@"官方赠送");
            break;
        default:
//            paymentString = @"支付方式";
            break;
    }
    return paymentString;
}

#pragma mark 激活按钮点击事件 //0流量/1通话/2大王卡/3双卡双待
- (IBAction)avtivateAction:(UIButton *)sender {
    self.isPaySuccess = NO;
    if (self.packageCategory == 2) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"￥%@", self.dicOrderDetail[@"list"][@"UnitPrice"]] message:INTERNATIONALSTRING(@"领取大王卡礼包") preferredStyle:UIAlertControllerStyleAlert];
        // 为防止block与控制器间循环引用，我们这里需用__weak来预防
        __weak typeof(alert) wAlert = alert;
        [alert addAction:[UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"确定") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            // 点击确定按钮的时候, 会调用这个block
            NSLog(@"%@",[wAlert.textFields.firstObject text]);
            //非空判断，回调激活
            if (![self isBlankString:[wAlert.textFields.firstObject text]]) {
                [self activateGiftRardActionWithTel:[wAlert.textFields.firstObject text]];
            } else {
                HUDNormal(INTERNATIONALSTRING(@"请输入手机号码"))
            }
            
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"取消") style:UIAlertActionStyleCancel handler:nil]];
        // 添加文本框(只能添加到UIAlertControllerStyleAlert的样式，如果是preferredStyle:UIAlertControllerStyleActionSheet则会崩溃)
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = INTERNATIONALSTRING(@"请输入手机号码");
            textField.font = [UIFont systemFontOfSize:17];
            textField.keyboardType = UIKeyboardTypeNumberPad;
            //监听文字改变的方法
            //        [textField addTarget:self action:@selector(textFieldsValueDidChange:) forControlEvents:UIControlEventEditingChanged];
        }];
        // 3.显示alertController:presentViewController
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        if ([[[self.dicOrderDetail objectForKey:@"list"] objectForKey:@"OrderStatus"] intValue] == 1 || [[[self.dicOrderDetail objectForKey:@"list"] objectForKey:@"OrderStatus"] intValue] == 4) {
            //已激活
            [self activityOrderActivited];
        } else {
            //未激活
            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
            OrderActivationViewController *orderActivationViewController = [mainStory instantiateViewControllerWithIdentifier:@"orderActivationViewController"];
            if (orderActivationViewController) {
                orderActivationViewController.dicOrderDetail = self.dicOrderDetail;
                [self.navigationController pushViewController:orderActivationViewController animated:YES];
            }
        }
    }
}

- (void)activityOrderActivited {
    if ([BlueToothDataManager shareManager].isConnected) {
        if ([BlueToothDataManager shareManager].isHaveCard && [[BlueToothDataManager shareManager].cardType isEqualToString:@"1"]) {
            //1.蓝牙连接之后才能走激活的接口
            [BlueToothDataManager shareManager].isShowHud = YES;
            HUDNoStop1(INTERNATIONALSTRING(@"正在激活..."))
            //2.套餐激活完成之后获取蓝牙发送的序列号
            [BlueToothDataManager shareManager].bleStatueForCard = 1;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"checkBLESerialNumber" object:self.dicOrderDetail[@"list"][@"OrderID"]];
        } else {
            HUDNormal(INTERNATIONALSTRING(@"请插入爱小器卡"))
        }
    } else {
        HUDNormal(INTERNATIONALSTRING(@"请连接蓝牙"))
    }
}

#pragma mark 取消激活按钮点击事件
- (IBAction)cancelActivateButtonAvtion:(UIButton *)sender {
    [self dj_alertAction:self alertTitle:nil actionTitle:@"继续" message:@"您将要取消此订单" alertAction:^{
        [self cancelOrder];
    }];
}

#pragma mark 取消订单接口
- (void)cancelOrder {
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[self.dicOrderDetail[@"list"] objectForKey:@"OrderID"],@"OrderID", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiOrderCancel params:params success:^(id responseObj) {
        NSLog(@"查询到的用户数据：%@",responseObj);
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            //套餐取消完成
            HUDNormal(responseObj[@"msg"])
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BuyConfrim" object:nil];
            [self.navigationController popViewControllerAnimated:YES];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            HUDNormal(responseObj[@"msg"])
        }
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}


#pragma mark 激活大王卡
- (void)activateGiftRardActionWithTel:(NSString *)tel {
    self.checkToken = YES;
    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:self.idOrder,@"OrderID", tel,@"Tel", nil];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiActivationKindCard params:info success:^(id responseObj) {
        NSLog(@"激活大王卡的结果：%@",responseObj);
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            //套餐激活完成
            HUDNormal(responseObj[@"msg"])
            [self cehckOrderInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"actionOrderSuccess" object:@"actionOrderSuccess"];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            HUDNormal(responseObj[@"msg"])
        }
        
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
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

@end
