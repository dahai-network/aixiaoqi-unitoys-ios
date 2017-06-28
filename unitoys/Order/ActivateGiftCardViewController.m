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
#import "UNDataTools.h"
#import "ExplainDetailsChildController.h"

#import "HTTPServer.h"
//#import "UNReadyActivateController.h"
#import "UNConvertFormatTool.h"
#import "UNMobileActivateController.h"

#import "ChooseWhereCardsViewController.h"


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
//出国后如何使用按钮
@property (weak, nonatomic) IBOutlet UIButton *btnHowToUseAbord;
//回国后恢复设置按钮
@property (weak, nonatomic) IBOutlet UIButton *btnResetGoBack;


@property (nonatomic, strong) HTTPServer *localHttpServer;//本地服务器


@property (nonatomic, assign) BOOL isAlreadyActivate;
@property (nonatomic, copy) NSString *selectDate;
@property (nonatomic, copy) NSString *orderID;

@end

@implementation ActivateGiftCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.isAbroadMessage) {
        self.title = INTERNATIONALSTRING(@"已购套餐详情");
    }else{
        self.title = INTERNATIONALSTRING(@"套餐详情");
    }
    
//    if (self.packageCategory != 2 && self.packageCategory != 3) {
//        [self setRightButton:INTERNATIONALSTRING(@"使用教程")];
//    }
//    [self setRightButton:INTERNATIONALSTRING(@"取消订单")];
    
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

- (void)cardInIphone {
    [super cardInIphone];
    NSLog(@"爱小器卡已放入手机");
    self.isPaySuccess = NO;
    
    self.isAlreadyActivate = [[self.dicOrderDetail objectForKey:@"OrderStatus"] intValue] == 1 ? YES : NO;
    self.selectDate = @"";
    self.orderID = self.dicOrderDetail[@"OrderID"];
    
    [self activeSIMCardInPhoneAction];
//    UNReadyActivateController *activate = [[UNReadyActivateController alloc] init];
//    activate.defaultDay = self.dicOrderDetail[@"ExpireDaysInt"];
//    activate.orderID = self.dicOrderDetail[@"OrderID"];
//    //状态有5种,只有为1才不需要激活
//    activate.isAlreadyActivate = [[self.dicOrderDetail objectForKey:@"OrderStatus"] intValue] == 1 ? YES : NO;
//    if ([self.dicOrderDetail[@"OrderStatus"] intValue] != 0) {
//        //只有状态为0才没有时间
////        activate.defaultDate = self.dicOrderDetail[@"ActivationDate"];
//        activate.defaultDate = [UNConvertFormatTool dateStringYMDFromTimeInterval:self.dicOrderDetail[@"ActivationDate"]];
//    }else{
//        activate.lastActivateDate = [self.dicOrderDetail[@"LastCanActivationDate"] doubleValue];
//    }
//    [self.navigationController pushViewController:activate animated:YES];
}

- (void)activeSIMCardInPhoneAction
{
    if (!self.isAlreadyActivate) {
        //直接获取卡数据
        UNLogLBEProcess(@"activeSIMCardInPhoneAction-激活");
        HUDNoStop1(@"")
        NSDictionary *info = @{@"OrderID":self.orderID, @"BeginDateTime":self.selectDate};
        NSString *apiNameStr = [NSString stringWithFormat:@"%@OrderID%@", @"apiOrderActivation", self.orderID];
        [UNNetworkManager postUrl:apiOrderActivation parameters:info success:^(ResponseType type, id  _Nullable responseObj) {
            HUDStop
            if (type == ResponseTypeSuccess) {
                [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
                [self activitySuccess];
            }else if (type == ResponseTypeFailed){
                HUDNormal(responseObj[@"msg"])
            }
        } failure:^(NSError * _Nonnull error) {
            HUDStop
            NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
            if (responseObj) {
                [self activitySuccess];
            }else{
                HUDNormal(@"激活失败")
            }
        }];
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
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            //获取激活码
            [self getActivateCode];
        }else if (type == ResponseTypeFailed){
            
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





- (void)cardInDevice {
    [super cardInDevice];
    [self startToActiviteCard];
}

- (void)whatIsAixiaoqiCard {
    self.isPaySuccess = NO;
    [super whatIsAixiaoqiCard];
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
//    NSLog(@"表头：%@",self.headers);
    [SSNetworkRequest getRequest:apiOrderById params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            
            self.dicOrderDetail = [responseObj objectForKey:@"data"][@"list"];
            self.packageCategory = [[self.dicOrderDetail objectForKey:@"PackageCategory"] intValue];
            setImage(self.firstCell.imgOrderView, [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"LogoPic"])
            self.packageId = responseObj[@"data"][@"list"][@"PackageId"];
            self.packageName = responseObj[@"data"][@"list"][@"PackageName"];
            self.IsSupport4G = responseObj[@"data"][@"list"][@"PackageIsSupport4G"];
            self.apnName = responseObj[@"data"][@"list"][@"PackageApnName"];
            if (self.packageCategory != 2 && [responseObj[@"data"][@"list"][@"OrderStatus"] intValue] == 0 && ![self.navigationItem.rightBarButtonItem.title isEqualToString:@"取消订单"]) {
//                [self setRightButton:INTERNATIONALSTRING(@"取消订单")];
            }
            
            if ([responseObj[@"data"][@"list"][@"PackageIsApn"] boolValue]) {
                if ([self.apnName isEqualToString:@"3gnet"]) {
                    self.IsApn= @(NO);
                }else{
                    self.IsApn = @(YES);
                }
            }else{
                self.IsApn = @(NO);
            }
            
            self.firstCell.lblOrderName.text = responseObj[@"data"][@"list"][@"PackageName"];
//            self.firstCell.lblOrderPrice.text = [NSString stringWithFormat:@"￥%@", responseObj[@"data"][@"list"][@"UnitPrice"]];
            [self.firstCell.lblOrderPrice changeLabelTexeFontWithString:[NSString stringWithFormat:@"￥%@", responseObj[@"data"][@"list"][@"UnitPrice"]]];
            [self.tableView reloadData];
            self.cancelButton.enabled = YES;
            self.activateButton.enabled = YES;
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
    } failure:^(id dataObj, NSError *error) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            self.dicOrderDetail = [responseObj objectForKey:@"data"];
            self.packageCategory = [[self.dicOrderDetail objectForKey:@"PackageCategory"] intValue];
            setImage(self.firstCell.imgOrderView, [[[responseObj objectForKey:@"data"] objectForKey:@"list"] objectForKey:@"LogoPic"])
            self.packageId = responseObj[@"data"][@"list"][@"PackageId"];
            self.packageName = responseObj[@"data"][@"list"][@"PackageName"];
            self.IsSupport4G = responseObj[@"data"][@"list"][@"PackageIsSupport4G"];
            
            self.IsApn = responseObj[@"data"][@"list"][@"PackageIsApn"];
            
            self.firstCell.lblOrderName.text = responseObj[@"data"][@"list"][@"PackageName"];
//            self.firstCell.lblOrderPrice.text = [NSString stringWithFormat:@"￥%@", responseObj[@"data"][@"list"][@"UnitPrice"]];
            [self.firstCell.lblOrderPrice changeLabelTexeFontWithString:[NSString stringWithFormat:@"￥%@", responseObj[@"data"][@"list"][@"UnitPrice"]]];
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
    [self dj_alertAction:self alertTitle:nil actionTitle:@"继续" message:@"您将要取消此订单" alertAction:^{
        [self cancelOrder];
    }];
//    NSLog(@"使用教程");
//    self.isPaySuccess = NO;
//    AbroadPackageExplainController *abroadVc = [[AbroadPackageExplainController alloc] init];
//    abroadVc.isSupport4G = [self.IsSupport4G boolValue];
//    abroadVc.isApn = [self.IsApn boolValue];
//    abroadVc.apnName = self.apnName;
//    [self .navigationController pushViewController:abroadVc animated:YES];
}

#pragma mark - tableView代理方法
//-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
//    return 0.01;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
//    return 0.01;
//}
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
                if ([[self.dicOrderDetail objectForKey:@"OrderStatus"] intValue] == 0) {
                    return 3;
                } else {
                    return 2;
                }
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
            
//            if (self.packageCategory == 2 || self.packageCategory == 3) {
//                self.firstCell.accessoryType = UITableViewCellAccessoryNone;
//            }else{
//                self.firstCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//            }
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
                    self.secondCell.lblContent.text = [self convertDateWithString:self.dicOrderDetail[@"LastCanActivationDate"]];
                } else if (indexPath.row == 1) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"套餐状态");
                    [self checkStatueWithLabel:self.secondCell.lblContent Statue:[[self.dicOrderDetail objectForKey:@"OrderStatus"] intValue]];
                } else {
                    NSLog(@"又出问题了");
                }
            } else {
                if (indexPath.row == 0) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"订单编号");
                    self.secondCell.lblContent.text = self.dicOrderDetail[@"OrderNum"];
                } else if (indexPath.row == 1) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"支付时间");
                    self.secondCell.lblContent.text = [self convertDateWithString:self.dicOrderDetail[@"PayDate"]];
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
                    self.secondCell.lblContent.text = [self checkPaymentModelWithPayment:self.dicOrderDetail[@"PaymentMethod"]];
                } else if (indexPath.row == 1) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"总价");
                    self.secondCell.lblContent.text = [NSString stringWithFormat:@"￥%@", self.dicOrderDetail[@"TotalPrice"]];
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
                    self.secondCell.lblContent.text = [self checkPaymentModelWithPayment:self.dicOrderDetail[@"PaymentMethod"]];
                } else if (indexPath.row == 1) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"有效期");
                    self.secondCell.lblContent.text = self.dicOrderDetail[@"ExpireDays"];
                } else {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"套餐状态");
                    [self checkStatueWithLabel:self.secondCell.lblContent Statue:[[self.dicOrderDetail objectForKey:@"OrderStatus"] intValue]];
                }
                return self.secondCell;
            } else if (self.packageCategory == 2 || self.packageCategory == 3) {
                self.thirdCell = [tableView dequeueReusableCellWithIdentifier:identifier3];
                if (!self.thirdCell) {
                    self.thirdCell=[[NSBundle mainBundle] loadNibNamed:@"ActivateGiftCardTableViewCell" owner:nil options:nil][2];
                }
                self.thirdCell.lblIntroduceFirst.text = self.dicOrderDetail[@"PackageFeatures"];
                self.thirdCell.lblIntroduceSecond.text = self.dicOrderDetail[@"PackageDetails"];
                return self.thirdCell;
            } else {
                self.secondCell = [tableView dequeueReusableCellWithIdentifier:identifier2];
                if (!self.secondCell) {
                    self.secondCell=[[NSBundle mainBundle] loadNibNamed:@"ActivateGiftCardTableViewCell" owner:nil options:nil][1];
                }
                if (indexPath.row == 0) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"支付方式");
                    self.secondCell.lblContent.text = [self checkPaymentModelWithPayment:self.dicOrderDetail[@"PaymentMethod"]];
                } else if (indexPath.row == 1) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"总价");
                    self.secondCell.lblContent.text = self.dicOrderDetail[@"TotalPrice"];
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
            if ([[self.dicOrderDetail objectForKey:@"OrderStatus"] intValue] == 0) {
                if (indexPath.row == 0) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"有效期");
                    self.secondCell.lblContent.text = self.dicOrderDetail[@"ExpireDays"];
                } else if (indexPath.row == 1) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"最晚激活日期");
                    self.secondCell.lblContent.text = [self convertDateWithString:self.dicOrderDetail[@"LastCanActivationDate"]];
                } else {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"套餐状态");
                    [self checkStatueWithLabel:self.secondCell.lblContent Statue:[[self.dicOrderDetail objectForKey:@"OrderStatus"] intValue]];
                }
                return self.secondCell;
            } else {
                if (indexPath.row == 0) {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"有效期");
                    self.secondCell.lblContent.text = self.dicOrderDetail[@"ExpireDays"];
                } else {
                    self.secondCell.lblContentName.text = INTERNATIONALSTRING(@"套餐状态");
                    [self checkStatueWithLabel:self.secondCell.lblContent Statue:[[self.dicOrderDetail objectForKey:@"OrderStatus"] intValue]];
                }
                return self.secondCell;
            }
            break;
    }
}

//0流量/1通话/2大王卡/3双卡双待
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        self.isPaySuccess = NO;
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
                label.text = [NSString stringWithFormat:@"%@ %@ %@", INTERNATIONALSTRING(@"剩余"), self.dicOrderDetail[@"RemainingCallMinutes"], INTERNATIONALSTRING(@"分钟")];
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
//    [self showChooseAlert];
    ChooseWhereCardsViewController *chooseCardsVC = [[ChooseWhereCardsViewController alloc] init];
    chooseCardsVC.orderID = self.dicOrderDetail[@"OrderID"];
    [self.navigationController pushViewController:chooseCardsVC animated:YES];
}

- (void)startToActiviteCard {
    self.isPaySuccess = NO;
    if (self.packageCategory == 2) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"￥%@", self.dicOrderDetail[@"UnitPrice"]] message:INTERNATIONALSTRING(@"领取大王卡礼包") preferredStyle:UIAlertControllerStyleAlert];
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
        if ([[self.dicOrderDetail objectForKey:@"OrderStatus"] intValue] == 1 || [[self.dicOrderDetail objectForKey:@"OrderStatus"] intValue] == 4) {
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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"checkBLESerialNumber" object:self.dicOrderDetail[@"OrderID"]];
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
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[self.dicOrderDetail objectForKey:@"OrderID"],@"OrderID", nil];
    
    [self getBasicHeader];
//    NSLog(@"表演头：%@",self.headers);
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
//    NSLog(@"表演头：%@",self.headers);
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

#pragma mark 出国后如何使用
- (IBAction)howToUseAbord:(UIButton *)sender {
    [self initExplainDetailsData:YES];
    self.isPaySuccess = NO;
}

#pragma mark 回国后恢复设置
- (IBAction)resetGoBack:(UIButton *)sender {
    [self initExplainDetailsData:NO];
    self.isPaySuccess = NO;
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


- (void)initExplainDetailsData:(BOOL)isGoAbroad
{
    if (isGoAbroad) {
        [self performSelector:@selector(configLocalHttpServer) withObject:nil afterDelay:1];
    }
    [self initDetailsData:isGoAbroad];
    [self pushDetailsVc];
}
- (void)initDetailsData:(BOOL)isGoAbroad
{
    NSMutableArray *dataArray = [NSMutableArray array];
    if (isGoAbroad) {
        NSDictionary *page1 = @{
                                @"nameTitle" : INTERNATIONALSTRING(@"插电话卡"),
                                @"detailTitle" : INTERNATIONALSTRING(@"将爱小器国际卡插入手机中,然后将您的国内电话卡插入到手环或双待王中"),
                                @"explainImage" : @"pic_cdhk",
                                @"pageType" : @(1),
                                };
        
        NSDictionary *page2 = @{
                                @"nameTitle" : INTERNATIONALSTRING(@"安装APN"),
                                @"detailTitle" : INTERNATIONALSTRING(@"点击按钮会跳转到系统设置,点击右上角\"安装\"按钮后,输入验证码同意安装"),
                                @"explainImage" : @"ios_apn",
                                @"buttonTitle" : INTERNATIONALSTRING(@"安装APN"),
                                @"buttonAction" : @"apnSettingAction",
                                @"pageType" : @(1),
                                };
        
        NSString *page3Title;
        NSString *page3ImageStr;
        if ([self.IsSupport4G boolValue]) {
            page3Title = INTERNATIONALSTRING(@"点击按钮会跳转到系统设置，点击\"蜂窝移动网络数据选项\"然后开启数据漫游,开启4G网络(或选择4G网络)");
            page3ImageStr = @"pic_ios_open_sj";
        }else{
            page3Title = INTERNATIONALSTRING(@"点击按钮会跳转到系统设置，点击\"蜂窝移动网络数据选项\"然后开启数据漫游,关闭4G网络(或选择3G网络)");
            page3ImageStr = @"pic_ios_sj";
        }
        NSDictionary *page3 = @{
                                @"nameTitle" : INTERNATIONALSTRING(@"修改移动网络设置"),
                                @"detailTitle" : page3Title,
                                @"explainImage" : page3ImageStr,
                                @"buttonTitle" : INTERNATIONALSTRING(@"移动网络设置"),
                                @"buttonAction" : @"gotoSystemSettingAction",
                                @"pageType" : @(1),
                                };
        
        NSDictionary *page4 = @{
                                //                            @"nameTitle" : INTERNATIONALSTRING(@"接打电话，收发短信"),
                                @"detailTitle" : INTERNATIONALSTRING(@"激活套餐后,在境外按以上步骤操作完成后,重启APP,即可免国际漫游在境外上网.接打电话,收发短信"),
                                @"pageType" : @(2),
                                };
        //根据类型确定需要添加的页面
        [dataArray addObject:page1];
        if ([self.IsApn boolValue]) {
            [dataArray addObject:page2];
        }
        [dataArray addObject:page3];
        [dataArray addObject:page4];
        [UNDataTools sharedInstance].isGoAbroad = YES;
        if ([UNDataTools sharedInstance].goAbroadTotalStep < dataArray.count - 1) {
            [UNDataTools sharedInstance].goAbroadTotalStep = dataArray.count - 1;
            [UNDataTools sharedInstance].goAbroadCurrentAbroadStep = 0;
        }
    }else{
        NSDictionary *page1 = @{
                                @"nameTitle" : INTERNATIONALSTRING(@"插电话卡"),
                                @"detailTitle" : INTERNATIONALSTRING(@"将爱小器国际卡从手机取出,然后将您的国内电话卡插回手机中"),
                                @"explainImage" : @"pic_hg_cdhk",
                                @"pageType" : @(1),
                                };
        
        NSDictionary *page2 = @{
                                @"nameTitle" : INTERNATIONALSTRING(@"删除APN"),
                                @"detailTitle" : INTERNATIONALSTRING(@"打开系统的APN设置页面,选择\"爱小器APN\",再点击\"删除描述文件\""),
                                @"explainImage" : @"pic_ios_hg_delapn",
                                @"buttonTitle" : INTERNATIONALSTRING(@"打开APN设置"),
                                @"buttonAction" : @"apnDeleteAction",
                                @"pageType" : @(1),
                                };
        
        NSString *page3Title;
        if ([self.IsSupport4G boolValue]) {
            page3Title = INTERNATIONALSTRING(@"点击按钮跳转到系统设置，点击\"蜂窝移动网络数据选项\"然后关闭数据漫游");
        }else{
            page3Title = INTERNATIONALSTRING(@"点击按钮会跳转到系统设置，点击\"蜂窝移动网络数据选项\"然后关闭数据漫游,开启4G网络");
        }
        NSDictionary *page3 = @{
                                @"nameTitle" : INTERNATIONALSTRING(@"修改移动网络设置"),
                                @"detailTitle" : page3Title,
                                @"explainImage" : @"pic_ios_hg_4g",
                                @"buttonTitle" : INTERNATIONALSTRING(@"移动网络设置"),
                                @"buttonAction" : @"gotoSystemSettingAction",
                                @"pageType" : @(1),
                                };
        
        //        NSDictionary *page4 = @{
        //                                //                            @"nameTitle" : INTERNATIONALSTRING(@"接打电话，收发短信"),
        //                                @"detailTitle" : INTERNATIONALSTRING(@"激活套餐后,在境外按以上步骤操作完成后,重启APP,即可免国际漫游在境外上网.接打电话,收发短信"),
        //                                @"pageType" : @(2),
        //                                };
        //根据类型确定需要添加的页面
        [dataArray addObject:page1];
        if ([self.IsApn boolValue]) {
            [dataArray addObject:page2];
        }
        [dataArray addObject:page3];
        [UNDataTools sharedInstance].isGoAbroad = NO;
        if ([UNDataTools sharedInstance].goHomeTotalStep < dataArray.count - 1) {
            [UNDataTools sharedInstance].goHomeTotalStep = dataArray.count - 1;
            [UNDataTools sharedInstance].goHomeCurrentAbroadStep = 0;
        }
    }
    [UNDataTools sharedInstance].pagesData = dataArray;
}

- (void)pushDetailsVc
{
    ExplainDetailsChildController *detailsVc = [[ExplainDetailsChildController alloc] init];
    detailsVc.rootClassName = NSStringFromClass([self class]);
    detailsVc.apnName = self.apnName;
    detailsVc.currentPage = 0;
    detailsVc.totalPage = [UNDataTools sharedInstance].pagesData.count - 1;
    [self.navigationController pushViewController:detailsVc animated:YES];
}
#pragma mark - 本地服务器
#pragma mark - 搭建本地服务器 并且启动
- (void)configLocalHttpServer{
    if (_localHttpServer) {
        [self startServer];
        return;
    }
    _localHttpServer = [[HTTPServer alloc] init];
    [_localHttpServer setType:@"_http.tcp"];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSLog(@"文件目录 -- %@",webPath);
    
    if (![fileManager fileExistsAtPath:webPath]){
        NSLog(@"File path error!");
    }else{
        NSString *webLocalPath = webPath;
        [_localHttpServer setDocumentRoot:webLocalPath];
        NSLog(@"webLocalPath:%@",webLocalPath);
        [self startServer];
    }
}
- (void)startServer {
    NSError *error;
    if([_localHttpServer start:&error]){
        NSLog(@"Started HTTP Server on port %hu", [_localHttpServer listeningPort]);
        [BlueToothDataManager shareManager].localServicePort = [NSString stringWithFormat:@"%d",[_localHttpServer listeningPort]];
    } else {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
}

-(void)dealloc
{
    if (_localHttpServer) {
        [_localHttpServer stop];
        _localHttpServer = nil;
    }
}

@end
