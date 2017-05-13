//
//  OpenConvenienceServiceController.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "OpenConvenienceServiceController.h"
#import "UITableView+RegisterNib.h"
#import <Masonry/Masonry.h>
#import "OpenServiceCell.h"
#import "OpenServiceMonthCell.h"
#import "SelectPayTypeCell.h"
#import "OpenServiceBottomView.h"
#import "OpenService2Cell.h"

#import <AlipaySDK/AlipaySDK.h>
#import "Order.h"
#import "WXApi.h"
#import "DataSigner.h"
#import "PaySuccessViewController.h"

@interface OpenConvenienceServiceController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) OpenServiceBottomView *bottomView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *cellDatas;

//当前购买月份(1.3.6.9.12)
@property (nonatomic, assign) NSInteger currentSelectMonth;
//当前支付方式(1:余额,2:微信,3:支付宝)
@property (nonatomic, assign) NSInteger currentPayType;
//剩余金钱
@property (nonatomic, assign) CGFloat surplusMoney;
//是否允许使用余额支付
@property (nonatomic, assign) BOOL isAllowPayUseMoney;
//当前选中支付类型
@property (nonatomic, weak) SelectPayTypeCell *selectPayCell;

//当前月套餐费用
@property (nonatomic, assign) CGFloat currentMonthPrice;
//现格
@property (nonatomic, assign) CGFloat nowPrice;
//原价
@property (nonatomic, assign) CGFloat beforePrice;
//当前选择价格
@property (nonatomic, assign) CGFloat currentOtherPrice;
//当前应付金额
@property (nonatomic, assign) CGFloat payPrice;

//订单数据
@property (nonatomic, copy) NSDictionary *dicOrder;
//订单id
@property (nonatomic, copy) NSString *orderID;
//套餐类型
@property (nonatomic, assign) int packageCategory;
@end

static NSString *openServiceCellID = @"OpenServiceCell";
static NSString *openService2CellID = @"OpenService2Cell";
static NSString *openServiceMonthCellID = @"OpenServiceMonthCell";
static NSString *selectPayTypeCellID = @"SelectPayTypeCell";

@implementation OpenConvenienceServiceController

- (NSArray *)cellDatas
{
    if (!_cellDatas) {
        _cellDatas = [NSArray array];
    }
    return _cellDatas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"开通省心服务";
    self.view.backgroundColor = UIColorFromRGB(0xf5f5f5);
    [self initData];
    [self initBottomView];
    [self initTableView];
    [self getDataFromServer];
    [self initCellDatas];
    [self updatePrice];
    [self loadAmmount];
}
- (void)initData
{
    //当前余额
    self.currentSelectMonth = 0;
    self.currentPayType = 0;
    if (self.surplusMoney) {
        self.isAllowPayUseMoney = YES;
    }else{
        self.isAllowPayUseMoney = NO;
    }
}

- (void) loadAmmount {
    self.checkToken = YES;
    [self getBasicHeader];
    [SSNetworkRequest getRequest:apiGetUserAmount params:nil success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            self.surplusMoney = [[[responseObj objectForKey:@"data"] objectForKey:@"amount"] floatValue];
            [self initData];
            [self initCellDatas];
            [self.tableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            
        }
        //        NSLog(@"查询到的用户数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}


- (void)initBottomView
{
    OpenServiceBottomView *bottomView = [[NSBundle mainBundle] loadNibNamed:@"OpenServiceBottomView" owner:self options:nil].lastObject;
    bottomView.surePayButton.enabled = NO;
    [bottomView.surePayButton addTarget:self action:@selector(surePayAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bottomView];
    self.bottomView = bottomView;
    [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.height.mas_equalTo(@54);
    }];
}

- (void)updatePrice
{
    self.payPrice = self.currentMonthPrice + self.currentSelectMonth * self.nowPrice;
    NSDictionary *smallDict = @{NSFontAttributeName : [UIFont systemFontOfSize:12]};
    NSDictionary *bigDict = @{NSFontAttributeName : [UIFont systemFontOfSize:21]};
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"￥" attributes:smallDict]];
    NSString *payString = [NSString stringWithFormat:@"%.2f", self.payPrice];
    NSArray *stringArray = [payString componentsSeparatedByString:@"."];
    if (stringArray.count) {
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@.", stringArray.firstObject] attributes:bigDict]];
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", stringArray.lastObject] attributes:smallDict]];
    }else{
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", payString] attributes:bigDict]];
    }
    self.bottomView.payMoneyLabel.attributedText = string;
    
    if (!self.currentMonthPrice || !self.currentSelectMonth || !self.currentPayType) {
        self.bottomView.surePayButton.backgroundColor = UIColorFromRGB(0xe5e5e5);
        [self.bottomView.surePayButton setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
        self.bottomView.surePayButton.enabled = NO;
    }else{
        self.bottomView.surePayButton.backgroundColor = UIColorFromRGB(0xf21f20);
        [self.bottomView.surePayButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.bottomView.surePayButton.enabled = YES;
    }
}

- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColorFromRGB(0xf5f5f5);
    self.tableView.sectionHeaderHeight = 0;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 10)];
    self.tableView.tableFooterView = footView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    [self.tableView registerNibWithNibId:openServiceCellID];
    [self.tableView registerNibWithNibId:openService2CellID];
    [self.tableView registerNibWithNibId:openServiceMonthCellID];
    [self.tableView registerNibWithNibId:selectPayTypeCellID];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).with.offset(-54);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
    }];
}

- (void)getDataFromServer
{

    if (self.packageDict) {
        self.nowPrice = [self.packageDict[@"Price"] floatValue];
        self.beforePrice = [self.packageDict[@"OriginalPrice"] floatValue];
    }
//    [self updatePrice];
    
    
//    self.checkToken = YES;
//    [self getBasicHeader];
//    [SSNetworkRequest getRequest:@"" params:nil success:^(id responseObj) {
//        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            self.nowPrice = 0;
//            self.beforePrice = 0;
//            [self.tableView reloadData];
//            [self updatePrice];
//        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//        }
//    } failure:^(id dataObj, NSError *error) {
//        HUDNormal(INTERNATIONALSTRING(@"网络连接失败"))
//        NSLog(@"啥都没：%@",[error description]);
//    } headers:self.headers];
}

- (void)initCellDatas
{
    _cellDatas = @[
                   @[
                       @{
                           @"cellName":@"月套餐费",
                           @"cellDetailName":@"请输入你的月套餐费",
                           @"allowEdit":@(YES),
                           @"cellHeight":@(120),
                           @"isHiddenLine":@(YES),
                           },
                       ],
                   @[
                       @{
                           @"cellName":@"通话时长",
                           @"cellDetailName":@"无限通话",
                           @"cellHeight":@(84),
                           @"isHiddenLine":@(NO),
                           },
                       @{
                           @"cellName":@"服务费用",
                           @"cellDetailName":[NSString stringWithFormat:@"现优惠:%.f元/月  ", self.nowPrice],
                           @"cellDetailAttriName":[NSString stringWithFormat:@"原价:%.f元/月", self.beforePrice],
                           @"cellHeight":@(84),
                           @"isHiddenLine":@(NO),
                           },
                       @{
                           @"cellName":@"购买月份",
                           @"cellHeight":@(177),
                           @"isHiddenLine":@(YES),
                           },
                   ],
                   @[
                       @{
                           @"cellName":@"选择支付方式",
                           @"cellHeight":@(40),
                           @"isHiddenLine":@(NO),
                           },
                       @{
                           @"cellIconName":@"order_amountpay",
                           @"cellName":[NSString stringWithFormat:@"余额支付(剩余￥%.2f)", self.surplusMoney],
                           @"cellHeight":@(60),
                           @"isHiddenLine":@(NO),
//                           @"cellSurplusMoneye":@(self.surplusMoney),
                           },
                       @{
                           @"cellIconName":@"order_weipay",
                           @"cellName":@"微信",
                           @"cellDetailName":@"推荐安装微信5.0版本以上的用户使用",
                           @"cellHeight":@(60),
                           @"isHiddenLine":@(NO),
                           },
                       @{
                           @"cellIconName":@"order_alipay",
                           @"cellName":@"支付宝",
                           @"cellDetailName":@"推荐有支付宝账户的用户使用",
                           @"cellHeight":@(60),
                           @"isHiddenLine":@(YES),
                           },
                       
                       ]
                   ];
    [self.tableView reloadData];
}

- (void)surePayAction:(UIButton *)button
{
    if (!self.payPrice) {
        return;
    }
    if (self.currentPayType == 1 && self.payPrice > self.surplusMoney) {
        HUDNormal(@"余额不足,建议使用其他方式支付");
        return;
    }
    button.enabled = NO;
    //提交订单
    [self commitOrder];
    button.enabled = YES;
}

- (void)startPay
{
    //确认支付
    if (self.currentPayType == 1) {
        //余额支付
        [self useMyMoneyPay];
    }else if(self.currentPayType == 2){
        //微信支付
        if ([self isWXAppInstalled]) {
            [self useWeChatPay];
        }
    }else if (self.currentPayType == 3){
        //支付宝支付
        [self useAliPay];
    }else{
        NSLog(@"支付类型错误");
    }
}

//#pragma mark --- 余额支付
//- (void)useMyMoneyPay
//{
//    NSLog(@"余额支付--%f", self.payPrice);
//}
//#pragma mark --- 微信支付
//- (void)useWeChatPay
//{
//    NSLog(@"微信支付--%f", self.payPrice);
//}
//#pragma mark --- 支付宝支付
//- (void)useAliPay
//{
//    NSLog(@"支付宝支付--%f", self.payPrice);
//}

- (void)monthPriceChange:(UITextField *)textField
{
    self.currentMonthPrice = [textField.text floatValue];
    [self updatePrice];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.cellDatas.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.cellDatas[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = self.cellDatas[indexPath.section][indexPath.row];
    if (indexPath.section == 0) {
        OpenServiceCell *cell = [tableView dequeueReusableCellWithIdentifier:openServiceCellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.nameLabel.text = dict[@"cellName"];
        cell.detailTextField.placeholder = dict[@"cellDetailName"];
        [cell.detailTextField addTarget:self action:@selector(monthPriceChange:) forControlEvents:UIControlEventEditingChanged];
        //监听文字
        return cell;
    }else if (indexPath.section == 1) {
        if (dict[@"cellDetailName"]) {
            OpenService2Cell *cell = [tableView dequeueReusableCellWithIdentifier:openService2CellID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.nameLabel.text = dict[@"cellName"];
            NSMutableAttributedString *attriString = [[NSMutableAttributedString alloc] init];
            NSAttributedString *string = [[NSAttributedString alloc] initWithString:dict[@"cellDetailName"] attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:16], NSForegroundColorAttributeName: UIColorFromRGB(0x333333)}];
            [attriString appendAttributedString:string];
            if (dict[@"cellDetailAttriName"]) {
                NSAttributedString *string2 = [[NSAttributedString alloc] initWithString:dict[@"cellDetailAttriName"] attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14], NSForegroundColorAttributeName: UIColorFromRGB(0xf21f20),NSStrikethroughStyleAttributeName:@(NSUnderlineStyleSingle|NSUnderlinePatternSolid),NSStrikethroughColorAttributeName:UIColorFromRGB(0xf21f20)}];
                [attriString appendAttributedString:string2];
            }
            cell.detailLabel.attributedText = attriString;
            if ([dict[@"isHiddenLine"] boolValue]) {
                cell.lineView.hidden = YES;
            }else{
                cell.lineView.hidden = NO;
            }
            return cell;
        }else{
            kWeakSelf
            OpenServiceMonthCell *cell = [tableView dequeueReusableCellWithIdentifier:openServiceMonthCellID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.selectMonthBlock = ^(NSInteger selectMonth) {
                weakSelf.currentSelectMonth= selectMonth;
                [weakSelf updatePrice];
            };
            return cell;
        }
    }else{
//        NSDictionary *dict = self.cellDatas[indexPath.section][indexPath.row];
        if (indexPath.row == 0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PayTypeCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PayTypeCell"];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.font = [UIFont systemFontOfSize:16];
                cell.textLabel.textColor = UIColorFromRGB(0x333333);
                UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(15, [self.cellDatas[indexPath.section][indexPath.row][@"cellHeight"] floatValue] - 1, kScreenWidthValue - 15 * 2, 1)];
                lineView.backgroundColor = UIColorFromRGB(0xe5e5e5);
                [cell addSubview:lineView];
            }
            cell.textLabel.text = dict[@"cellName"];
            return cell;
        }else{
            SelectPayTypeCell *cell = [tableView dequeueReusableCellWithIdentifier:selectPayTypeCellID];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.iconImageView.image = [UIImage imageNamed:dict[@"cellIconName"]];
            cell.nameLabel.text = dict[@"cellName"];
            if (indexPath.row == 1) {
                if (self.isAllowPayUseMoney) {
                    cell.backgroundColor = [UIColor whiteColor];
                }else{
                    cell.backgroundColor = UIColorFromRGB(0xe5e5e5);
                }
            }else{
                cell.backgroundColor = [UIColor whiteColor];
            }
            if (dict[@"cellDetailName"]) {
                cell.nameLabelBottom.constant = -2.5;
                cell.descLabel.hidden = NO;
                cell.descLabel.text = dict[@"cellDetailName"];
            }else{
                cell.nameLabelBottom.constant = 8.0;
                cell.descLabel.hidden = YES;
            }
            if (_currentPayType == indexPath.row) {
                cell.selectImageVIew.image = [UIImage imageNamed:@"order_checked"];
            }else{
                cell.selectImageVIew.image = [UIImage imageNamed:@"order_uncheck"];
            }
            if ([dict[@"isHiddenLine"] boolValue]) {
                cell.lineView.hidden = YES;
            }else{
                cell.lineView.hidden = NO;
            }
            return cell;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 2){
        return 10;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.cellDatas[indexPath.section][indexPath.row][@"cellHeight"] floatValue];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 || indexPath.section == 1) {
        return;
    }else{
        if (indexPath.row == 0) {
            return;
        }else{
            if (indexPath.row == 1) {
                if (!self.isAllowPayUseMoney) {
                    return;
                }
            }
            _currentPayType = indexPath.row;
            if (self.selectPayCell) {
                self.selectPayCell.selectImageVIew.image= [UIImage imageNamed:@"order_uncheck"];
            }
            self.selectPayCell = [tableView cellForRowAtIndexPath:indexPath];
            self.selectPayCell.selectImageVIew.image = [UIImage imageNamed:@"order_checked"];
            [self updatePrice];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

#pragma mark --- 余额支付
- (void)useMyMoneyPay
{
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[self.dicOrder objectForKey:@"OrderID"],@"OrderID", nil];
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiPayOrderByUserAmount params:params success:^(id responseObj) {
        NSLog(@"查询到的用户数据：%@",responseObj);
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
            if (storyboard) {
                PaySuccessViewController *paySuccessViewController = [storyboard instantiateViewControllerWithIdentifier:@"paySuccessViewController"];
                
                if (paySuccessViewController) {
                    
                    paySuccessViewController.strHintInfo = INTERNATIONALSTRING(@"充值成功");
                    paySuccessViewController.strPayMethod = INTERNATIONALSTRING(@"余额支付");
                    paySuccessViewController.strPayAmount = [NSString stringWithFormat:@"%.2f",self.payPrice];
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


- (BOOL)isWXAppInstalled
{
    // 1.判断是否安装微信
    NSLog(@"%d",[WXApi isWXAppInstalled]);
    if (![WXApi isWXAppInstalled]) {
        HUDNormal(INTERNATIONALSTRING(@"您尚未安装\"微信App\",请先安装后再返回支付"));
        return NO;
    }
    // 2.判断微信的版本是否支持最新Api
    if (![WXApi isWXAppSupportApi]) {
        HUDNormal(INTERNATIONALSTRING(@"您微信当前版本不支持此功能,请先升级微信应用"));
        return NO;
    }
    return YES;
}

- (void)useWeChatPay {
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[self.dicOrder objectForKey:@"OrderNum"],@"orderOrPayment", nil];
    
    [self getBasicHeader];
    //    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest postRequest:apiGetPrepayID params:params success:^(id responseObj) {
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

- (void)useAliPay {
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
}



- (BOOL)commitOrder {
    self.checkToken = YES;
    NSString *paymentMethod;
    if (self.currentPayType==3) {
        //支付宝
        paymentMethod = @"1";
    } else if(self.currentPayType==2) {
        //微信
        paymentMethod = @"2";
    }else if(self.currentPayType==1) {
        //余额
        paymentMethod = @"3";
    }else{
        NSLog(@"支付类型出错");
        return NO;
    }
    if (!paymentMethod) {
        return NO;
    }
    NSDictionary *params = @{@"PackageId":self.packageDict[@"PackageId"], @"Quantity" : [NSString stringWithFormat:@"%ld", self.currentSelectMonth], @"PaymentMethod": paymentMethod, @"MonthPackageFee":[NSString stringWithFormat:@"%.2f",self.currentMonthPrice]};
    HUDNoStop1(INTERNATIONALSTRING(@"正在提交订单..."))
    [self getBasicHeader];
    [SSNetworkRequest postRequest:apiOrderAdd params:params success:^(id responseObj) {
        NSLog(@"查询到的订单数据：%@",responseObj);
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            self.dicOrder = [[responseObj objectForKey:@"data"] objectForKey:@"order"];
            self.orderID = self.dicOrder[@"OrderID"];
            self.packageCategory = [self.dicOrder[@"PackageCategory"] intValue];
            [self startPay];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            HUDNormal(INTERNATIONALSTRING(@"支付失败"))
        }
        /*
         [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];*/
    } failure:^(id dataObj, NSError *error) {
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
    return YES;
}


@end
