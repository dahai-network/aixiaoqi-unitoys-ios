//
//  UNReadyActivateController.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/7.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNReadyActivateController.h"
#import "UITableView+RegisterNib.h"
#import "UNReadyActivateCell.h"
#import "UNMobileActivateController.h"

@interface UNReadyActivateController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSString *selectDate;

//@property (nonatomic, weak) UIPickerView *pickerView;
@property (weak, nonatomic) UIView *valueView;
//@property (nonatomic, weak) UILabel *titleLabel;

@property (nonatomic, weak) UIDatePicker *datePicker;
@end

static NSString *activateCellID = @"UNReadyActivateCell";
@implementation UNReadyActivateController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"在手机内激活";
    [self initTableView];
    [self initPickerView];
}

//初始化tableView
- (void)initTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView registerNibWithNibId:activateCellID];
    self.tableView.un_height -= 64;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = UIColorFromRGB(0xf5f5f5);
    self.tableView.rowHeight = 55;
    
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 10)];
    self.tableView.tableHeaderView = topView;
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, 100)];
    UIButton *activeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    activeButton.backgroundColor = DefultColor;
    activeButton.layer.cornerRadius = 25;
    activeButton.layer.masksToBounds = YES;
    activeButton.frame = CGRectMake(15, 25, kScreenWidthValue - 30, 50);
    [activeButton setTitle:@"立即激活" forState:UIControlStateNormal];
    [activeButton addTarget:self action:@selector(activeAction:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:activeButton];
    
    self.tableView.tableFooterView = bottomView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    
    [self.tableView reloadData];
}

- (void)initPickerView
{
    UIView *valueView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    valueView.un_height -= 64;
    valueView.backgroundColor = [UIColor colorWithRed:32/255 green:34/255 blue:42/255 alpha:0.2];
    
    UIButton *btnOK = [[UIButton alloc] initWithFrame:CGRectMake(0,valueView.un_height - 35 - 1, self.view.bounds.size.width, 35)];
    btnOK.hidden = NO;
    [btnOK setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnOK setTitle:INTERNATIONALSTRING(@"确定") forState:UIControlStateNormal];
    [btnOK setBackgroundColor:[UIColor whiteColor]];
    [btnOK addTarget:self action:@selector(selectValue) forControlEvents:UIControlEventTouchUpInside];
    [valueView addSubview:btnOK];
    
    //创建一个UIPickView对象
    UIDatePicker *datePicker = [[UIDatePicker alloc]init];
    self.datePicker = datePicker;
    //自定义位置
    datePicker.frame = CGRectMake(0, valueView.un_height - 180 - 40, kScreenWidthValue, 180);
    //设置背景颜色
    datePicker.backgroundColor = [UIColor whiteColor];
    //datePicker.center = self.center;
    //设置本地化支持的语言（在此是中文)
    datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"zh"];
    //显示方式是只显示年月日
    datePicker.datePickerMode = UIDatePickerModeDate;
    //放在盖板上
    [valueView addSubview:datePicker];
    
    [self.view addSubview:valueView];
    valueView.hidden = YES;
    self.valueView = valueView;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.valueView addGestureRecognizer:tap];
    
}

- (void)selectValue
{
    NSLog(@"%@", self.datePicker);
    NSDate *date = self.datePicker.date;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    self.selectDate = [dateFormatter stringFromDate:date];
    
    [self.valueView setHidden:YES];
    self.tableView.scrollEnabled = self.valueView.hidden;
    
    [self.tableView reloadData];
}

- (void)tapAction {
    if (!self.valueView.hidden) {
        self.valueView.hidden = YES;
        self.tableView.scrollEnabled = self.valueView.hidden;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UNReadyActivateCell *cell = [tableView dequeueReusableCellWithIdentifier:activateCellID];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.row == 0) {
        cell.nameLabel.text = @"选择生效时间";
        cell.dateLabel.hidden = NO;
        cell.iconImageView.hidden = NO;
        cell.dayLabel.hidden = YES;
        if (self.selectDate) {
            cell.dateLabel.text = self.selectDate;
        }
    }else{
        cell.nameLabel.text = @"有效时长";
        cell.dateLabel.hidden = YES;
        cell.iconImageView.hidden = YES;
        cell.dayLabel.hidden = NO;
        if (self.defaultDay) {
            cell.dayLabel.text = [NSString stringWithFormat:@"%@天", self.defaultDay];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row == 0) {
        //弹出选择日期控件
//        [self initPickerView];
        self.valueView.hidden = NO;
    }
}

- (void)activeAction:(UIButton *)button
{
    if (!self.selectDate || [self.selectDate isEqualToString:@""]) {
        HUDNormal(@"请选择生效时间");
        return;
    }
//    button.enabled = NO;
    NSLog(@"激活");
//    HUDNoStop1(INTERNATIONALSTRING(@"正在激活..."))
//    self.checkToken = YES;
//    NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:self.dicOrderDetail[@"OrderID"],@"OrderID", self.selectedDateString,@"BeginTime", nil];
//    
//    [self getBasicHeader];
//    //            NSLog(@"表演头：%@",self.headers);
//    [SSNetworkRequest postRequest:apiOrderActivation params:info success:^(id responseObj) {
//        NSLog(@"查询到的用户数据：%@",responseObj);
//        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            //2.套餐激活完成之后获取蓝牙发送的序列号
//            [BlueToothDataManager shareManager].bleStatueForCard = 1;
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"checkBLESerialNumber" object:self.dicOrderDetail[@"OrderID"]];
    //获取激活码
//        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//            [BlueToothDataManager shareManager].isShowHud = NO;
//            HUDStop
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//            [self.activityOrderButton setTitle:@"重新激活" forState:UIControlStateNormal];
//        }else{
//            //数据请求失败
//            HUDStop
//            [BlueToothDataManager shareManager].isShowHud = NO;
//            //            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
//            HUDNormal(responseObj[@"msg"])
//            [self.activityOrderButton setTitle:INTERNATIONALSTRING(@"重新激活") forState:UIControlStateNormal];
//        }
//        
//    } failure:^(id dataObj, NSError *error) {
//        //
//        NSLog(@"啥都没：%@",[error description]);
//        HUDNormal(@"激活失败")
//        [BlueToothDataManager shareManager].isShowHud = NO;
//        [self.activityOrderButton setTitle:INTERNATIONALSTRING(@"重新激活") forState:UIControlStateNormal];
//    } headers:self.headers];
    
    //网络请求激活
    
    UNMobileActivateController * activateVc = [[UNMobileActivateController alloc] init];
    [self.navigationController pushViewController:activateVc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
