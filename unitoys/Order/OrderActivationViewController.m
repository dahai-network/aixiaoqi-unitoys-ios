//
//  OrderActivationViewController.m
//  unitoys
//
//  Created by sumars on 16/10/23.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "OrderActivationViewController.h"
#import "BlueToothDataManager.h"
#import "BindDeviceViewController.h"
#import "ChooseDeviceTypeViewController.h"

@interface OrderActivationViewController ()
@property (nonatomic, strong)UIDatePicker *pickerView;
@property (nonatomic, strong)UILabel *titleLabel;
@property (nonatomic, strong)UIView *valueView;
@property (nonatomic, copy)NSString *selectedDateString;
@property (weak, nonatomic) IBOutlet UIButton *activityOrderButton;
@property (nonatomic, strong)UIWindow *notBoundAlertWindow;
@property (nonatomic, strong)ChooseDeviceTypeViewController *chooseDeviceTypeVC;
@property (weak, nonatomic) IBOutlet UIImageView *refreshImg;

@end

@implementation OrderActivationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.lblExprieDays.text = [NSString stringWithFormat:@"%@",[self.dicOrderDetail objectForKey:@"ExpireDays"]];
    if ([BlueToothDataManager shareManager].isBounded) {
        if ([BlueToothDataManager shareManager].isConnected) {
            if ([BlueToothDataManager shareManager].isHaveCard && [[BlueToothDataManager shareManager].cardType isEqualToString:@"1"]) {
                self.lblDeviceStatus.text = INTERNATIONALSTRING(@"已连接");
            } else {
                self.lblDeviceStatus.text = INTERNATIONALSTRING(@"未插入爱小器手机卡");
            }
        } else {
            self.lblDeviceStatus.text = INTERNATIONALSTRING(@"未连接");
        }
    } else {
        self.lblDeviceStatus.text = INTERNATIONALSTRING(@"未绑定");
    }
    
    UIView *valueView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    valueView.backgroundColor = [UIColor colorWithRed:32/255 green:34/255 blue:42/255 alpha:0.2];
    
    UIDatePicker *pickerview = [[UIDatePicker alloc] initWithFrame: CGRectMake(0,self.view.bounds.size.height-210,self.view.bounds.size.width,105)];
    pickerview.datePickerMode = UIDatePickerModeDate;
    pickerview.minimumDate = [NSDate date];
    
    NSTimeInterval time=[self.dicOrderDetail[@"LastCanActivationDate"] doubleValue];
    NSDate *lasteddate=[NSDate dateWithTimeIntervalSince1970:time];
    pickerview.maximumDate = lasteddate;
    
    self.lblActivationDate.text = @"---- -- --";
//    [self setDateForSelectedWithSelected:[NSDate date]];
    NSDate *defaultDate = [NSDate date];
    pickerview.date = defaultDate;//设置UIDatePicker默认显示时间
    
    [pickerview setBackgroundColor:[UIColor whiteColor]];
    [valueView addSubview:pickerview];
    self.pickerView = pickerview;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMinY(pickerview.frame) - 41, self.view.bounds.size.width, 40)];
    titleLabel.backgroundColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = INTERNATIONALSTRING(@"生效日期");
    [valueView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UIButton *btnOK = [[UIButton alloc] initWithFrame:CGRectMake(0,CGRectGetMaxY(pickerview.frame) + 3, self.view.bounds.size.width, 35)];
    btnOK.hidden = NO;
    [btnOK setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnOK setTitle:INTERNATIONALSTRING(@"确定") forState:UIControlStateNormal];
    [btnOK setBackgroundColor:[UIColor whiteColor]];
    
    [btnOK addTarget:self action:@selector(selectValue) forControlEvents:UIControlEventTouchUpInside];
    [valueView addSubview:btnOK];
    
    [self.view addSubview:valueView];
    valueView.hidden = YES;
    self.valueView = valueView;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.valueView addGestureRecognizer:tap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionOrderStatueSuccess) name:@"actionOrderSuccess" object:@"actionOrderSuccess"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionOrderStatueFail) name:@"actionOrderStatueFail" object:@"actionOrderStatueFail"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView) name:@"changeStatueAll" object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated {
    self.selectedDateString = nil;
}

- (void)refreshTableView {
    if ([BlueToothDataManager shareManager].isBounded) {
        if ([BlueToothDataManager shareManager].isConnected) {
            if ([BlueToothDataManager shareManager].isHaveCard && [[BlueToothDataManager shareManager].cardType isEqualToString:@"1"]) {
                self.lblDeviceStatus.text = INTERNATIONALSTRING(@"已连接");
            } else {
                self.lblDeviceStatus.text = INTERNATIONALSTRING(@"未插入爱小器手机卡");
            }
        } else {
            self.lblDeviceStatus.text = INTERNATIONALSTRING(@"未连接");
        }
    } else {
        self.lblDeviceStatus.text = INTERNATIONALSTRING(@"未绑定");
    }
    [self.tableView reloadData];
}

- (void)actionOrderStatueSuccess {
    self.activityOrderButton.hidden = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actionOrderStatueFail {
    [self.activityOrderButton setTitle:INTERNATIONALSTRING(@"重新激活") forState:UIControlStateNormal];
}

- (void)selectValue {
    self.valueView.hidden = YES;
    [self setDateForSelectedWithSelected:self.pickerView.date];
}

- (void)setDateForSelectedWithSelected:(NSDate *)date {
    NSDateFormatter *forma = [[NSDateFormatter alloc]init];
    NSDateFormatter *forma1 = [[NSDateFormatter alloc]init];
    [forma setDateFormat:@"YYYY-MM-dd 00:00:00"];
    [forma1 setDateFormat:@"YYYY-MM-dd"];
    NSString *str = [forma stringFromDate:date]; //UIDatePicker显示的时间
    self.lblActivationDate.text = [forma1 stringFromDate:date];
    NSLog(@"time===%@",str);
    NSDate *tempDate = [forma dateFromString:str];
    NSString *convertTime = [NSString stringWithFormat:@"%ld", (long)[tempDate timeIntervalSince1970]/*+ 8*3600*/];
    NSLog(@"timeSp:%@",convertTime); //时间戳的值
    self.selectedDateString = convertTime;
}

- (void)tapAction {
    if (!self.valueView.hidden) {
        self.valueView.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 15;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return 15;
    } else {
        return 0.01;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
        {
            [self startAnimation];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self showNotBoundAlertWindow];
            });
        }
            break;
        case 1:
            if (indexPath.row == 0) {
                self.valueView.hidden = NO;
            }
            break;
        default:
            break;
    }
}

- (void)startAnimation {
    //    进行Layer层旋转的
    //    后面的字符串是固定名字，读取系统的文件信息
    CABasicAnimation *base = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    base.duration = 1;
    //    起始的角度
    base.fromValue = @(0);
    //    终止的角度
    base.toValue = @(M_PI_2 * 2);
    //    将这个动画添加到layer上
    [self.refreshImg.layer addAnimation:base forKey:@"base"];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)activationOrder:(id)sender {
    if ([BlueToothDataManager shareManager].isBounded) {
        if ([BlueToothDataManager shareManager].isConnected) {
            if ([BlueToothDataManager shareManager].isHaveCard && [[BlueToothDataManager shareManager].cardType isEqualToString:@"1"]) {
                if (self.selectedDateString) {
                    //1.蓝牙连接之后才能走激活的接口
                    [BlueToothDataManager shareManager].isShowHud = YES;
                    HUDNoStop1(INTERNATIONALSTRING(@"正在激活..."))
                    self.checkToken = YES;
                    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:self.dicOrderDetail[@"OrderID"],@"OrderID", self.selectedDateString,@"BeginTime", nil];
                    
                    [self getBasicHeader];
                    [SSNetworkRequest postRequest:apiOrderActivation params:info success:^(id responseObj) {
                        NSLog(@"查询到的用户数据：%@",responseObj);
                        if ([[responseObj objectForKey:@"status"] intValue]==1) {
                            //2.套餐激活完成之后获取蓝牙发送的序列号
                            [BlueToothDataManager shareManager].bleStatueForCard = 1;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"checkBLESerialNumber" object:self.dicOrderDetail[@"OrderID"]];
                        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                            [BlueToothDataManager shareManager].isShowHud = NO;
                            HUDStop
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
                            [self.activityOrderButton setTitle:@"重新激活" forState:UIControlStateNormal];
                        }else{
                            //数据请求失败
                            HUDStop
                            [BlueToothDataManager shareManager].isShowHud = NO;
                            //            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
                            HUDNormal(responseObj[@"msg"])
                            [self.activityOrderButton setTitle:INTERNATIONALSTRING(@"重新激活") forState:UIControlStateNormal];
                        }
                        
                    } failure:^(id dataObj, NSError *error) {
                        //
                        NSLog(@"啥都没：%@",[error description]);
                        HUDNormal(@"激活失败")
                        [BlueToothDataManager shareManager].isShowHud = NO;
                        [self.activityOrderButton setTitle:INTERNATIONALSTRING(@"重新激活") forState:UIControlStateNormal];
                    } headers:self.headers];
                } else {
                    HUDNormal(@"请选择激活时间")
                }
            } else {
                [self showNotBoundAlertWindow];
            }
        } else {
            [self showNotBoundAlertWindow];
        }
    } else {
        [self showNotBoundAlertWindow];
    }
}

- (void)showNotBoundAlertWindow {
    if (!self.notBoundAlertWindow) {
        self.notBoundAlertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.notBoundAlertWindow.windowLevel = UIWindowLevelStatusBar;
        self.notBoundAlertWindow.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hiddenWindow)];
                [self.notBoundAlertWindow addGestureRecognizer:tap];
        
        UIView *littleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        littleView.un_width = kScreenWidthValue-70;
        littleView.un_height = littleView.un_width*173.00/305.00;
        littleView.un_left = 35;
        littleView.un_top = kScreenHeightValue/2-littleView.un_height/2;
        littleView.backgroundColor = [UIColor whiteColor];
        littleView.layer.masksToBounds = YES;
        littleView.layer.cornerRadius = 10;
        [self.notBoundAlertWindow addSubview:littleView];
        
        UIButton *checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        checkButton.un_left = 0;
        checkButton.un_width = littleView.un_width;
        checkButton.un_height = littleView.un_height*0.28323;
        checkButton.un_top = littleView.un_height-checkButton.un_height;
        if (![BlueToothDataManager shareManager].isBounded) {
            [checkButton setTitle:@"去绑定设备" forState:UIControlStateNormal];
        } else {
            [checkButton setTitle:@"好的" forState:UIControlStateNormal];
        }
        checkButton.titleLabel.font = [UIFont systemFontOfSize:21];
        [checkButton setTitleColor:UIColorFromRGB(0x00a0e9) forState:UIControlStateNormal];
        [checkButton addTarget:self action:@selector(goToBoundDevice:) forControlEvents:UIControlEventTouchUpInside];
        [littleView addSubview:checkButton];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, checkButton.un_top-1, littleView.un_width, 1)];
        lineView.backgroundColor = UIColorFromRGB(0xe5e5e5);
        [littleView addSubview:lineView];
        
        UILabel *upLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, littleView.un_height*0.2, littleView.un_width, 21)];
        if ([BlueToothDataManager shareManager].isBounded) {
            if ([BlueToothDataManager shareManager].isConnected) {
                if ([BlueToothDataManager shareManager].isHaveCard && [[BlueToothDataManager shareManager].cardType isEqualToString:@"1"]) {
                    NSLog(@"已插入爱小器卡，%s,%d", __FUNCTION__, __LINE__);
                } else {
                    upLabel.text = @"未插入爱小器卡";
                }
            } else {
                upLabel.text = @"爱小器设备未连接到手机";
            }
        } else {
            upLabel.text = @"去绑定设备";
        }
        upLabel.textAlignment = NSTextAlignmentCenter;
        upLabel.textColor = UIColorFromRGB(0x333333);
        upLabel.font = [UIFont systemFontOfSize:16];
        [littleView addSubview:upLabel];
        
        UILabel *downLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, lineView.un_top-littleView.un_height*0.2-upLabel.un_height, littleView.un_width, upLabel.un_height)];
        if ([BlueToothDataManager shareManager].isBounded) {
            if ([BlueToothDataManager shareManager].isConnected) {
                if ([BlueToothDataManager shareManager].isHaveCard && [[BlueToothDataManager shareManager].cardType isEqualToString:@"1"]) {
                    NSLog(@"已插入爱小器卡，%s,%d", __FUNCTION__, __LINE__);
                } else {
                    downLabel.text = @"请检查爱小器设备的卡盖是否闭合";
                }
            } else {
                downLabel.text = @"请检查爱小器设备是否电量充足";
            }
        } else {
            downLabel.text = @"绑定成功后请继续完成激活过程";
        }
        downLabel.textAlignment = NSTextAlignmentCenter;
        downLabel.textColor = UIColorFromRGB(0x333333);
        downLabel.font = [UIFont systemFontOfSize:16];
        [littleView addSubview:downLabel];
        
        [self.notBoundAlertWindow makeKeyAndVisible];
    }
}

- (void)hiddenWindow {
    self.notBoundAlertWindow.hidden = YES;
    self.notBoundAlertWindow = nil;
    [self.notBoundAlertWindow makeKeyAndVisible];
}

- (void)goToBoundDevice:(UIButton *)sender {
    [self hiddenWindow];
    if ([sender.titleLabel.text isEqualToString:@"去绑定设备"]) {
        if ([BlueToothDataManager shareManager].isOpened) {
            //跳转到设备界面
            if ([BlueToothDataManager shareManager].isBounded) {
                //有绑定
                UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
                BindDeviceViewController *bindDeviceViewController = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
                if (bindDeviceViewController) {
                    self.tabBarController.tabBar.hidden = YES;
                    bindDeviceViewController.hintStrFirst = [BlueToothDataManager shareManager].statuesTitleString;
                    [self.navigationController pushViewController:bindDeviceViewController animated:YES];
                }
            } else {
                //没绑定
                if (!self.chooseDeviceTypeVC) {
                    self.chooseDeviceTypeVC = [[ChooseDeviceTypeViewController alloc] init];
                }
                [self.navigationController pushViewController:self.chooseDeviceTypeVC animated:YES];
            }
        } else {
            HUDNormal(@"蓝牙未开")
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"actionOrderSuccess" object:@"actionOrderSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"actionOrderStatueFail" object:@"actionOrderStatueFail"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeStatueAll" object:nil];
}

@end
