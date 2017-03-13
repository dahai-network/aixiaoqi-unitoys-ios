//
//  OrderActivationViewController.m
//  unitoys
//
//  Created by sumars on 16/10/23.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "OrderActivationViewController.h"
#import "BlueToothDataManager.h"

@interface OrderActivationViewController ()
@property (nonatomic, strong)UIDatePicker *pickerView;
@property (nonatomic, strong)UILabel *titleLabel;
@property (nonatomic, strong)UIView *valueView;
@property (nonatomic, copy)NSString *selectedDateString;
@property (weak, nonatomic) IBOutlet UIButton *activityOrderButton;

@end

@implementation OrderActivationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.lblExprieDays.text = [NSString stringWithFormat:@"%@",[[self.dicOrderDetail objectForKey:@"list"] objectForKey:@"ExpireDays"]];
    if ([BlueToothDataManager shareManager].isConnected) {
        self.lblDeviceStatus.text = @"已连接";
    } else {
        self.lblDeviceStatus.text = @"未连接";
    }
    
    UIView *valueView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    valueView.backgroundColor = [UIColor colorWithRed:32/255 green:34/255 blue:42/255 alpha:0.2];
    
    UIDatePicker *pickerview = [[UIDatePicker alloc] initWithFrame: CGRectMake(0,self.view.bounds.size.height-210,self.view.bounds.size.width,105)];
    pickerview.datePickerMode = UIDatePickerModeDate;
    pickerview.minimumDate = [NSDate date];
    [self setDateForSelectedWithSelected:[NSDate date]];
    NSDate *defaultDate = [NSDate date];
    pickerview.date = defaultDate;//设置UIDatePicker默认显示时间
    
    [pickerview setBackgroundColor:[UIColor whiteColor]];
    [valueView addSubview:pickerview];
    self.pickerView = pickerview;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMinY(pickerview.frame) - 41, self.view.bounds.size.width, 40)];
    titleLabel.backgroundColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = @"生效日期";
    [valueView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UIButton *btnOK = [[UIButton alloc] initWithFrame:CGRectMake(0,CGRectGetMaxY(pickerview.frame) + 3, self.view.bounds.size.width, 35)];
    btnOK.hidden = NO;
    [btnOK setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnOK setTitle:@"确定" forState:UIControlStateNormal];
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
    
}

- (void)actionOrderStatueSuccess {
    self.activityOrderButton.hidden = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actionOrderStatueFail {
    [self.activityOrderButton setTitle:@"重新激活" forState:UIControlStateNormal];
}

- (void)selectValue {
    self.valueView.hidden = YES;
    [self setDateForSelectedWithSelected:self.pickerView.date];
}

- (void)setDateForSelectedWithSelected:(NSDate *)date {
    NSDateFormatter *forma = [[NSDateFormatter alloc]init];
    NSDateFormatter *forma1 = [[NSDateFormatter alloc]init];
    [forma setDateFormat:@"YYYY-MM-dd 00:00:00"];
    [forma1 setDateFormat:@"YYYY年MM月dd日"];
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
    if (indexPath.section == 1 && indexPath.row == 0) {
        self.valueView.hidden = NO;
    }
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
    if ([BlueToothDataManager shareManager].isConnected) {
        if ([BlueToothDataManager shareManager].isHaveCard) {
            //1.蓝牙连接之后才能走激活的接口
            [BlueToothDataManager shareManager].isShowHud = YES;
            HUDNoStop1(@"正在激活...")
            self.checkToken = YES;
            NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:self.dicOrderDetail[@"list"][@"OrderID"],@"OrderID", self.selectedDateString,@"BeginTime", nil];
            
            [self getBasicHeader];
            NSLog(@"表演头：%@",self.headers);
            [SSNetworkRequest postRequest:apiOrderActivation params:info success:^(id responseObj) {
                NSLog(@"查询到的用户数据：%@",responseObj);
                if ([[responseObj objectForKey:@"status"] intValue]==1) {
                    //2.套餐激活完成之后获取蓝牙发送的序列号
                    [BlueToothDataManager shareManager].bleStatueForCard = 1;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"checkBLESerialNumber" object:self.dicOrderDetail[@"list"][@"OrderID"]];
                }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                    HUDStop
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
                    [self.activityOrderButton setTitle:@"重新激活" forState:UIControlStateNormal];
                }else{
                    //数据请求失败
                    HUDStop
                    //            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
                    HUDNormal(responseObj[@"msg"])
                    [self.activityOrderButton setTitle:@"重新激活" forState:UIControlStateNormal];
                }
                
            } failure:^(id dataObj, NSError *error) {
                //
                NSLog(@"啥都没：%@",[error description]);
                HUDNormal(@"激活失败")
                [self.activityOrderButton setTitle:@"重新激活" forState:UIControlStateNormal];
            } headers:self.headers];
        } else {
            HUDNormal(@"请插入爱小器卡")
        }
    } else {
        HUDNormal(@"请先连接蓝牙")
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"actionOrderSuccess" object:@"actionOrderSuccess"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"actionOrderStatueFail" object:@"actionOrderStatueFail"];
}

@end
