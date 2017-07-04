//
//  OrderListViewController.m
//  unitoys
//
//  Created by sumars on 16/9/29.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "OrderListViewController.h"
#import "OrderListTableViewCell.h"
#import "OrderDetailViewController.h"
#import "UIImageView+WebCache.h"
#import "BindGiftBagCardViewController.h"
#import "ActivateGiftCardViewController.h"
#import "CommunicatePackageViewController.h"
#import "AbroadPackageDescView.h"
#import "UNDatabaseTools.h"
#import "CutomButton.h"
#import "OrderActivationViewController.h"
#import "ConvenienceOrderDetailController.h"
#import "BlueToothDataManager.h"
#import "UNReadyActivateController.h"
#import "UNConvertFormatTool.h"
#import "UNMobileActivateController.h"
#import "ChooseWhereCardsViewController.h"


@interface OrderListViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
//@property (strong, nonatomic) IBOutlet UIView *sectionView;
@property (weak, nonatomic) IBOutlet UIButton *activitedButton;//已激活
@property (weak, nonatomic) IBOutlet UIButton *notActivitedButton;//未激活
@property (weak, nonatomic) IBOutlet UIButton *isEndButton;//已结束
@property (strong, nonatomic) IBOutlet UIView *footView;
@property (weak, nonatomic) IBOutlet UILabel *noDataLabel;
@property (nonatomic, copy) NSString *statueStr;//记录当前状态
@property (nonatomic ,strong)NSDictionary *currentInfo;

//@property (nonatomic, assign) BOOL isAlreadyActivate;
//@property (nonatomic, copy) NSString *selectDate;
//@property (nonatomic, copy) NSString *orderID;
@end

@implementation OrderListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.isAbroadMessage) {
        self.title = INTERNATIONALSTRING(@"已购境外套餐");
        [self setRightButton:INTERNATIONALSTRING(@"套餐超市")];
    }else{
        self.title = @"我的套餐";
        //右边按钮
//        UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"mypackge_add"] style:UIBarButtonItemStyleDone target:self action:@selector(rightButtonAction)];
//        self.navigationItem.rightBarButtonItem = right;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkOrderListForNotAct) name:@"actionOrderSuccess" object:@"actionOrderSuccess"];//激活成功
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkOrderListForNotAct) name:@"BuyConfrim" object:nil];//取消
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkOrderListForNotAct) name:@"boundGiftCardSuccess" object:@"boundGiftCardSuccess"];//绑定礼包卡成功
    }
    
    self.tableView.tableFooterView = self.footView;
    self.tableView.rowHeight = 60;
    self.statueStr = @"0";
    [self checkOrderListWithOrderStatus:self.statueStr];
    [self goToRreshWithTableView:self.tableView];
    [self.notActivitedButton setTitleColor:UIColorFromRGB(0x00a0e9) forState:UIControlStateNormal];

}

-(void)requesetOfPage:(NSInteger)page{
//    HUDNoStop1(INTERNATIONALSTRING(@"正在加载..."))
    if (page) {
        self.CurrentPage = page;
    }
    [self checkOrderListWithOrderStatus:self.statueStr];
}

- (void)checkOrderListForNotAct {
    [self.dataSourceArray removeAllObjects];
    [self.tableView.mj_footer resetNoMoreData];
    [self requesetOfPage:1];
//    [self checkOrderListWithOrderStatus:self.statueStr];
}

- (void)rightButtonClick
{
    if (self.isAbroadMessage) {
        [self markButtonAction];
    }
}

#pragma mark 已激活
- (IBAction)activitedAction:(UIButton *)sender {
    [self.activitedButton setTitleColor:UIColorFromRGB(0x00a0e9) forState:UIControlStateNormal];
    [self.notActivitedButton setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
    [self.isEndButton setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
    self.statueStr = @"1";
//    [self checkOrderListWithOrderStatus:self.statueStr];
    [self.dataSourceArray removeAllObjects];
    [self.tableView.mj_footer resetNoMoreData];
    [self requesetOfPage:1];
}

#pragma mark 未激活
- (IBAction)notActivitedAction:(UIButton *)sender {
    [self.activitedButton setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
    [self.notActivitedButton setTitleColor:UIColorFromRGB(0x00a0e9) forState:UIControlStateNormal];
    [self.isEndButton setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
    self.statueStr = @"0";
//    [self checkOrderListWithOrderStatus:self.statueStr];
    [self.dataSourceArray removeAllObjects];
    [self.tableView.mj_footer resetNoMoreData];
    [self requesetOfPage:1];
}

#pragma mark 已结束
- (IBAction)isEndAction:(UIButton *)sender {
    [self.activitedButton setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
    [self.notActivitedButton setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
    [self.isEndButton setTitleColor:UIColorFromRGB(0x00a0e9) forState:UIControlStateNormal];
    self.statueStr = @"2";
//    [self checkOrderListWithOrderStatus:self.statueStr];
    [self.dataSourceArray removeAllObjects];
    [self.tableView.mj_footer resetNoMoreData];
    [self requesetOfPage:1];
}

- (void)markButtonAction
{
    NSLog(@"套餐超市");
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
    UIViewController *countryListViewController = [mainStory instantiateViewControllerWithIdentifier:@"countryListViewController"];
    if (countryListViewController) {
        self.tabBarController.tabBar.hidden = YES;
        [self.navigationController pushViewController:countryListViewController animated:YES];
    }
}

- (void)rightButtonAction {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *firstAlertAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"通话套餐") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        CommunicatePackageViewController *communicateVC = [[CommunicatePackageViewController alloc] init];
        [self.navigationController pushViewController:communicateVC animated:YES];
    }];
    
    UIAlertAction *secondAlertAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"国际流量套餐") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Package" bundle:nil];
        UIViewController *countryListViewController = [mainStory instantiateViewControllerWithIdentifier:@"countryListViewController"];
        if (countryListViewController) {
            self.tabBarController.tabBar.hidden = YES;
            [self.navigationController pushViewController:countryListViewController animated:YES];
        }
    }];
    
    UIAlertAction *thirdAlertAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"绑定套餐礼包卡") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
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

- (void)checkOrderListWithOrderStatus:(NSString *)statue {
    HUDNoStop1(INTERNATIONALSTRING(@"正在加载..."))
    self.checkToken = YES;
    NSMutableDictionary *info=[NSMutableDictionary new];
    NSString *apiNameStr;
    if (self.isAbroadMessage) {
        [info setValue:@(self.CurrentPage) forKey:@"PageNumber"];
        [info setValue:@"20" forKey:@"PageSize"];
        [info setValue:@"0" forKey:@"PackageCategory"];
        
        apiNameStr = [NSString stringWithFormat:@"%@PackageCategory%@", @"apiOrderList", @"0"];
    }else{
        [info setValue:@(self.CurrentPage) forKey:@"PageNumber"];
        [info setValue:@"20" forKey:@"PageSize"];
//        [info setValue:statue forKey:@"OrderStatus"];
        
        apiNameStr = [NSString stringWithFormat:@"%@PackageCategory", @"apiOrderList"];
    }
//    NSLog(@"当前打印的页数 == %ld", (long)self.CurrentPage);
    [self getBasicHeader];
//    NSLog(@"表头：%@",self.headers);
    
    [SSNetworkRequest getRequest:apiOrderList params:info success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            NSArray *listArr = [[responseObj objectForKey:@"data"] objectForKey:@"list"];
            if (listArr.count) {
                [self.dataSourceArray addObjectsFromArray:listArr];
                if (listArr.count < 20) {
                    [self.tableView.mj_footer endRefreshingWithNoMoreData];
                }
            } else {
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
            }
            if (!self.dataSourceArray.count) {
                self.noDataLabel.hidden = NO;
                self.footView.un_height = 70;
                switch ([statue intValue]) {
                    case 0:
//                        HUDNormal(@"没有未激活的套餐")
                        self.noDataLabel.text = @"没有未激活的套餐";
                        break;
                    case 1:
//                        HUDNormal(@"没有已激活的套餐")
                        self.noDataLabel.text = @"没有已激活的套餐";
                        break;
                    case 2:
//                        HUDNormal(@"没有已过期的套餐")
                        self.noDataLabel.text = @"没有已过期的套餐";
                        break;
                    default:
                        break;
                }
            } else {
                self.noDataLabel.hidden = YES;
                self.footView.un_height = 0;
            }
            
            [self.tableView reloadData];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
//        NSLog(@"查询到的套餐数据：%@",responseObj[@"msg"]);
    } failure:^(id dataObj, NSError *error) {
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)activityActionNow:(CutomButton *)sender {
    NSDictionary *info = self.dataSourceArray[sender.indexPath.row];
    ChooseWhereCardsViewController *chooseWhereCardVC = [[ChooseWhereCardsViewController alloc] init];
    chooseWhereCardVC.isAlreadyActivate = [[self.currentInfo objectForKey:@"OrderStatus"] intValue] == 1 ? YES : NO;
    chooseWhereCardVC.orderID = info[@"OrderID"];
    [self.navigationController pushViewController:chooseWhereCardVC animated:YES];
}


- (void)activityOrderActivitedWithID:(NSString *)orderID {
    if ([BlueToothDataManager shareManager].isConnected) {
        if ([BlueToothDataManager shareManager].isHaveCard && [[BlueToothDataManager shareManager].cardType isEqualToString:@"1"]) {
            //1.蓝牙连接之后才能走激活的接口
            [BlueToothDataManager shareManager].isShowHud = YES;
            HUDNoStop1(INTERNATIONALSTRING(@"正在激活..."))
            //2.套餐激活完成之后获取蓝牙发送的序列号
            [BlueToothDataManager shareManager].bleStatueForCard = 1;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"checkBLESerialNumber" object:orderID];
        } else {
            HUDNormal(INTERNATIONALSTRING(@"请插入爱小器卡"))
        }
    } else {
        HUDNormal(INTERNATIONALSTRING(@"请连接蓝牙"))
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSourceArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    return 110;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 50;
//}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    return self.sectionView;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"OrderListTableViewCell";
    OrderListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell=[[[NSBundle mainBundle] loadNibNamed:@"OrderListTableViewCell" owner:nil options:nil] firstObject];
        [cell.activityButton addTarget:self action:@selector(activityActionNow:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (self.dataSourceArray.count) {
        NSDictionary *dicOrder = [self.dataSourceArray objectAtIndex:indexPath.row];
        //    cell.ivLogoPic.image = [[UIImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:[dicOrder objectForKey:@"LogoPic"]]]];
        [cell.ivLogoPic sd_setImageWithURL:[NSURL URLWithString:[dicOrder objectForKey:@"LogoPic"]]];
        cell.lblFlow.text = [dicOrder objectForKey:@"PackageName"];//[NSString stringWithFormat:@"流量:%dMB",[[dicOrder objectForKey:@"Flow"] intValue]/1024];
        cell.lblExpireDays.text = [dicOrder objectForKey:@"ExpireDays"];
        //    cell.lblPrice.text = [NSString stringWithFormat:@"￥%.2f",[[dicOrder objectForKey:@"TotalPrice"] floatValue]];
        [cell.lblPrice changeLabelTexeFontWithString:[NSString stringWithFormat:@"￥%.2f",[[dicOrder objectForKey:@"TotalPrice"] floatValue]]];
        cell.activityButton.indexPath = indexPath;
        //    cell.lblTotalPrice.font = [UIFont systemFontOfSize:15 weight:2];
        if ([[dicOrder objectForKey:@"PayStatus"] intValue]==0) {
            NSLog(@"未支付");
        }else{
            //order_actived
            switch ([[dicOrder objectForKey:@"OrderStatus"] intValue]) {
                case 0:
                    [cell.activityButton setTitle:INTERNATIONALSTRING(@"去激活") forState:UIControlStateNormal];
                    cell.activityButton.hidden = NO;
                    //                [cell.activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                    //                [cell.activityButton setImage:[UIImage imageNamed:@"order_unactive"] forState:UIControlStateNormal];
                    break;
                case 1:
                    [cell.activityButton setTitle:INTERNATIONALSTRING(@"已激活") forState:UIControlStateNormal];
                    cell.activityButton.hidden = YES;
                    //                if ([[dicOrder objectForKey:@"PackageCategory"] intValue] == 1) {
                    //                    [cell.activityButton setTitle:[NSString stringWithFormat:@"%@ %@ %@", INTERNATIONALSTRING(@"剩余"), dicOrder[@"RemainingCallMinutes"], INTERNATIONALSTRING(@"分钟")] forState:UIControlStateNormal];
                    ////                    [cell.activityButton setImage:nil forState:UIControlStateNormal];
                    //                } else {
                    //                    [cell.activityButton setTitle:INTERNATIONALSTRING(@"已激活") forState:UIControlStateNormal];
                    ////                    [cell.activityButton setImage:[UIImage imageNamed:@"order_actived"] forState:UIControlStateNormal];
                    //                }
                    //                [cell.activityButton setTitleColor:[UIColor colorWithRed:23/255.0 green:186/255.0 blue:34/255.0 alpha:1.0] forState:UIControlStateNormal];
                    break;
                case 2:
                    [cell.activityButton setTitle:INTERNATIONALSTRING(@"已过期") forState:UIControlStateNormal];
                    cell.activityButton.hidden = YES;
                    //                [cell.activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                    //                [cell.activityButton setImage:[UIImage imageNamed:@"order_unactive"] forState:UIControlStateNormal];
                    break;
                case 3:
                    [cell.activityButton setTitle:INTERNATIONALSTRING(@"已取消") forState:UIControlStateNormal];
                    cell.activityButton.hidden = YES;
                    //                [cell.activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                    //                [cell.activityButton setImage:[UIImage imageNamed:@"order_unactive"] forState:UIControlStateNormal];
                    break;
                case 4:
                    [cell.activityButton setTitle:INTERNATIONALSTRING(@"去激活") forState:UIControlStateNormal];
                    //                [cell.activityButton setTitle:INTERNATIONALSTRING(@"激活失败") forState:UIControlStateNormal];
                    cell.activityButton.hidden = NO;
                    //                [cell.activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                    //                [cell.activityButton setImage:[UIImage imageNamed:@"order_unactive"] forState:UIControlStateNormal];
                    break;
                    
                default:
                    [cell.activityButton setTitle:INTERNATIONALSTRING(@"未知状态") forState:UIControlStateNormal];
                    cell.activityButton.hidden = YES;
                    //                [cell.activityButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
                    //                [cell.activityButton setImage:[UIImage imageNamed:@"order_unactive"] forState:UIControlStateNormal];
                    break;
            }
        }
        
        //    cell.activityButton.text = [dicOrder objectForKey:@"Operators"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (self.dataSourceArray.count) {
        NSDictionary *dicOrder = [self.dataSourceArray objectAtIndex:indexPath.row];
        if ([dicOrder[@"PackageCategory"] isEqualToString:@"4"] || [dicOrder[@"PackageCategory"] isEqualToString:@"5"]) {
            ConvenienceOrderDetailController *convenienceOrderVc = [[ConvenienceOrderDetailController alloc] init];
            convenienceOrderVc.orderDetailId = dicOrder[@"OrderID"];
            [self.navigationController pushViewController:convenienceOrderVc animated:YES];
        }else{
            ActivateGiftCardViewController *giftCardVC = [[ActivateGiftCardViewController alloc] init];
            giftCardVC.packageCategory = [dicOrder[@"PackageCategory"] intValue];
            giftCardVC.idOrder = dicOrder[@"OrderID"];
            giftCardVC.isAbroadMessage = self.isAbroadMessage;
            [self.navigationController pushViewController:giftCardVC animated:YES];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.isAbroadMessage) {
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"isShowAbroadPackageDescView"] boolValue]) {
            [AbroadPackageDescView showAbroadPackageDescViewWithTitle:INTERNATIONALSTRING(@"使用简介") Desc:INTERNATIONALSTRING(@"1）出国前在套餐超市中，购买需前往地的套餐，然后将它激活到爱小器国际卡。\n2）出国后将爱小器国际卡插入手机，实现上网，然后将国内电话卡插入爱小器智能设备，通过APP接打电话，收发短信。") SureButtonTitle:INTERNATIONALSTRING(@"知道了,以后不再提醒")];
            [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:@"isShowAbroadPackageDescView"];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"actionOrderSuccess" object:@"actionOrderSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BuyConfrim" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundGiftCardSuccess" object:@"boundGiftCardSuccess"];
}

@end
