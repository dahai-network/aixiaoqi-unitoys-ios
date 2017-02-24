//
//  SportDataViewController.m
//  unitoys
//
//  Created by sumars on 16/11/24.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "SportDataViewController.h"
#import "SportDataCell.h"
#import "BlueToothDataManager.h"
#import "IsBoundingViewController.h"

#import "AFNetworking.h"



@interface SportDataViewController ()
@property (strong, nonatomic) IBOutlet UITableView *sportTableView;
@property (nonatomic, strong) NSMutableArray *rainbowColors;
@property (weak, nonatomic) IBOutlet UIView *noDataView;
@property (nonatomic, copy)NSString *todayDate;

@end

@implementation SportDataViewController

- (NSMutableArray *)arrSportData {
    if (!_arrSportData) {
        self.arrSportData = [NSMutableArray array];
    }
    return _arrSportData;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = nil;
    
    NSDate *todayDate= [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone localTimeZone];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"MM月dd日"];
    self.todayDate = [formatter stringFromDate:todayDate];
    
    self.currentDate = [NSDate dateWithTimeIntervalSinceNow:0];
    [self checkdayStepData];
//    if (![BlueToothDataManager shareManager].isBounded) {
//        [self dj_alertAction:self alertTitle:nil actionTitle:@"去绑定" message:@"您还没有绑定设备，是否要绑定？" alertAction:^{
//            if ([BlueToothDataManager shareManager].isOpened) {
//                IsBoundingViewController *isBoundVC = [[IsBoundingViewController alloc] init];
//                [self.navigationController pushViewController:isBoundVC animated:YES];
//                //绑定设备
//                if ([BlueToothDataManager shareManager].isConnected) {
//                    //点击绑定设备
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"boundingDevice" object:@"bound"];
//                } else {
//                    //未连接设备，先扫描连接
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
//                }
//            } else {
//                HUDNormal(@"请先开启蓝牙")
//            }
//        }];
//    }
    
    [BlueToothDataManager shareManager].movingTarget = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"][@"MovingTarget"];
    
    
    CGFloat height = 361*self.view.bounds.size.width/375;
    self.vwSumary.bounds = CGRectMake(0, 0, self.view.bounds.size.width, height);
    
    [self setBarTitle:[NSDate date]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSStepDataWithNoti:) name:@"stepChanged" object:@"toSport"];
    // Do any additional setup after loading the view.
}

#pragma mark 计算当日总步数
- (void)countCurrentDayStepNumber {
    self.currentDayTotalStep = 0;
    if (self.arrSportData.count) {
        for (NSDictionary *dicSportData in self.arrSportData) {
            NSString *stepNum = dicSportData[@"StepNum"];
            self.currentDayTotalStep += [stepNum intValue];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    self.tabBarController.tabBar.hidden = NO;
}

- (void)viewDidAppear:(BOOL)animated{
    [self refreshSStepDataWithNoti:nil];
    [self.lpvPercent needsUpdateConstraints];
    if ([BlueToothDataManager shareManager].isBounded) {
        if (![BlueToothDataManager shareManager].currentStep) {
            //发送请求当前步数的通知
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"checkCurrentStep" object:@"currentStep"];
        }
        //发送请求历史步数通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"checkPastStep" object:@"pastStep"];
    }else {
//        [self showAlertWithMessage:@"您还没有绑定设备，请先绑定设备"];
    }
    //设置完成情况
    [self proportionNumWithDuration:1.0];
}

#pragma mark 设置环形进度条的百分比
- (void)proportionNumWithDuration:(CFTimeInterval)duration {
    int currentStep;
    if ([BlueToothDataManager shareManager].isBounded && [_btnBarTitle.titleLabel.text isEqualToString:self.todayDate]) {
        currentStep = [[BlueToothDataManager shareManager].currentStep intValue];
    } else {
        if (self.currentDayTotalStep) {
            if (self.currentDayTotalStep != 0) {
                currentStep = self.currentDayTotalStep;
            } else {
                currentStep = 0;
            }
        } else {
            currentStep = 0;
        }
    }
    int targetStep = [[BlueToothDataManager shareManager].movingTarget intValue];
    float proportion = (float)currentStep/targetStep;
    currentStep < targetStep ? [self setPercent:proportion * [AnnularProgressBar intValue] :targetStep duration:duration] : [self setPercent:[AnnularProgressBar intValue] :targetStep duration:duration];
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
-(void) setBarTitle:(NSDate *)date {
    if (!self.currentDate) {
        self.currentDate = [NSDate date];
    }
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone localTimeZone];
    
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"MM月dd日"];

    
    [_btnBarTitle setTitle:[formatter stringFromDate:date] forState:UIControlStateNormal];
}

#pragma mark 设置环形进度条的相关属性
- (void) setPercent:(int)value :(int)maxValue duration:(CFTimeInterval)duration {
    CGFloat height = self.lpvPercent.bounds.size.height;
    self.lpvPercent.total = [AnnularProgressBar intValue];
    self.lpvPercent.color = RGB(0.0, 124.0, 188.0);
    self.lpvPercent.radius = height/2;
    self.lpvPercent.innerRadius = (height-30)/2;
    self.lpvPercent.startAngle = M_PI * 0.72;
    self.lpvPercent.endAngle = M_PI * 2.28;
    self.lpvPercent.animationDuration = duration;
    self.lpvPercent.layer.shouldRasterize = YES;
    
    [self.lpvPercent setCompleted:value];
    
}



- (IBAction)choiceDate:(id)sender {
    if (!self.calendar) {
        NSDate *date = [[NSDate date] dateByAddingTimeInterval:-360*24*60*60];
        NSTimeInterval a=[date timeIntervalSince1970];
        int timeStr = [[NSString stringWithFormat:@"%0.f", a] intValue];
        NSNumber *num = [NSNumber numberWithInt:timeStr];
        NSNumber *days = [NSNumber numberWithInt:360];
        
        self.checkToken = YES;
        [self getBasicHeader];
        NSMutableDictionary *info = [NSMutableDictionary new];
        [info setValue:num forKey:@"startDate"];
        [info setValue:days forKey:@"days"];
        
        
        [SSNetworkRequest getRequest:apiGetRecordDate params:info success:^(id responseObj) {
            
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                NSLog(@"查询到的记录的运动日期：%@",responseObj);
                NSArray *arr = responseObj[@"data"];
                
                if (arr) {
                    /*if ([arr count]>0)*/ {  //先请求是否有可用日期数据
                        NSDate *date = [NSDate date];
                        NSTimeZone *zone = [NSTimeZone systemTimeZone];
                        NSInteger interval = [zone secondsFromGMTForDate: date];
                        NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
                        localeDate = date;
                        
                        FDCalendar *calendar = [[FDCalendar alloc] initWithCurrentDate:localeDate delegate:self disableDate:arr];
                        CGRect frame = calendar.frame;
                        //        frame.origin.y = 20;
                        //        calendar.frame = frame;
                        calendar.frame = CGRectMake(frame.origin.x, frame.origin.y+20, frame.size.width, frame.size.height);
                        //        calendar.delegate = self;
                        
                        
                        
                        
                        //        [self.view addSubview:calendar];
                        
                        //注释此行,将日添加到window上,以覆盖tabbar
//                        [self.navigationController.view addSubview:calendar];
                        
                        
                        self.calendar = calendar;
                    }
                }
                
                //            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadCalendar" object:arr];
                
                /*
                 for (NSDictionary *dict in arr) {
                 NSString *dataStr = [self convertTimeToTimeStringWithTime:dict[@"Date"]];
                 NSLog(@"记录的时间为：%@", dataStr);
                 }*/
                
                
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
                
                
            }else{
                //数据请求失败
                NSLog(@"数据请求失败");
                
                
                
            }
            
            
            
        } failure:^(id dataObj, NSError *error) {
            //
            NSLog(@"啥都没：%@",[error description]);
            
        } headers:self.headers];
        
    }else{
//        [self.calendar setHidden:NO];
        [self.calendar showCalendar];
    }
}

- (IBAction)showProfile:(id)sender {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    if (storyboard) {
        self.tabBarController.tabBar.hidden = YES;
        UIViewController *profileViewController = [storyboard instantiateViewControllerWithIdentifier:@"profileViewController"];
        if (profileViewController) {
            [self.navigationController pushViewController:profileViewController animated:YES];
        }
    }
}

#pragma mark -UITableViewDataSource 
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.arrSportData.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SportDataCell *dataCell = [tableView dequeueReusableCellWithIdentifier:@"SportDataCell"];
    
    NSDictionary *dicSportData = [self.arrSportData objectAtIndex:indexPath.row];
    NSLog(@"运动记录：%@",dicSportData);
    NSString *startTimeStr = [[self convertTimeToTimeStringWithTime:dicSportData[@"StartDateTime"]] substringWithRange:NSMakeRange(11, 5)];
    NSString *endTimeStr = [[self convertTimeToTimeStringWithTime:dicSportData[@"EndDateTime"]] substringWithRange:NSMakeRange(11, 5)];
    NSString *stepNum = dicSportData[@"StepNum"];
    NSString *distance = dicSportData[@"KM"];
    NSString *consume = dicSportData[@"Kcal"];
    dataCell.lblSportTime.text = [NSString stringWithFormat:@"%@-%@ 活动", startTimeStr, endTimeStr];
    dataCell.stepNum.text = stepNum;
    dataCell.distance.text = distance;
    dataCell.consume.text = consume;
    return dataCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 取消cell的选中效果
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -FDCalendarDelegate
- (void)DidSelectDate:(NSDate *)date {
    //选择日期后，查询相应日期的运动数据
    [self setBarTitle:date];
    self.currentDate = date;
//    [self.calendar setHidden:YES];
    //隐藏日历
    [self.calendar hiddenCalendar];
    
    [self checkdayStepData];
    //查询相关运动日期
//    [self checkNotedStepDataWithDate:self.currentDate dayCount:@"31"];
}

#pragma mark 获取当天运动数据
- (void)checkdayStepData {
    //获取当前时间的时间戳
//    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a=[self.currentDate timeIntervalSince1970];
    int timeStr = [[NSString stringWithFormat:@"%0.f", a] intValue];
    NSNumber *num = [NSNumber numberWithInt:timeStr];
    
    self.checkToken = YES;
    [self getBasicHeader];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:num,@"date", nil];
    [SSNetworkRequest getRequest:apiGetTimePeriodByDate params:params success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"查询到的带时间的运动数据：%@",responseObj);
            self.arrSportData = responseObj[@"data"][@"TimePeriods"];
            [self countCurrentDayStepNumber];
            //设置完成情况
            [self proportionNumWithDuration:1.0];
            [self refreshSStepDataWithNoti:nil];
            if (!self.arrSportData.count) {
                self.noDataView.hidden = NO;
            } else {
                self.noDataView.hidden = YES;
            }
            [self.sportTableView reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"数据请求失败");
        }
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 获取记录的运动日期
- (void)checkNotedStepDataWithDate:(NSDate *)date dayCount:(NSString *)dayCount {
    NSTimeInterval a=[date timeIntervalSince1970];
    int timeStr = [[NSString stringWithFormat:@"%0.f", a] intValue];
    NSNumber *num = [NSNumber numberWithInt:timeStr];
    NSNumber *days = [NSNumber numberWithInt:[dayCount intValue]];
    
    self.checkToken = YES;
    [self getBasicHeader];
    NSMutableDictionary *info = [NSMutableDictionary new];
    [info setValue:num forKey:@"startDate"];
    [info setValue:days forKey:@"days"];
    [SSNetworkRequest getRequest:apiGetRecordDate params:info success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"查询到的记录的运动日期：%@",responseObj);
            NSArray *arr = responseObj[@"data"];
            for (NSDictionary *dict in arr) {
                NSString *dataStr = [self convertTimeToTimeStringWithTime:dict[@"Date"]];
                NSLog(@"记录的时间为：%@", dataStr);
            }
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            NSLog(@"数据请求失败");
        }
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

#pragma mark 收到通知，更新步数
- (void)refreshSStepDataWithNoti:(NSNotification *)sender {
    self.lblTarget.text = [BlueToothDataManager shareManager].sportDays;
    //从后台获得
    self.lblKM.text = [BlueToothDataManager shareManager].distance;
    self.lblKcal.text = [BlueToothDataManager shareManager].consume;
    //实时获取数据
    if ([BlueToothDataManager shareManager].isBounded && [_btnBarTitle.titleLabel.text isEqualToString:self.todayDate]) {
        self.lblDayout.text = [BlueToothDataManager shareManager].currentStep;
    } else {
        if (self.currentDayTotalStep) {
            self.lblDayout.text = [NSString stringWithFormat:@"%d", self.currentDayTotalStep];
        } else {
            self.lblDayout.text = @"0";
        }
    }
    //设置完成情况
    if (sender) {
        [self proportionNumWithDuration:0.0];
    } else {
        [self proportionNumWithDuration:1.0];
    }
}

#pragma mark 将时间戳转换为时间
- (NSString *)convertTimeToTimeStringWithTime:(NSString *)timeStr {
    NSTimeInterval time=[timeStr doubleValue];//因为时差问题要加8小时 == 28800 sec?
    NSDate *detaildate=[NSDate dateWithTimeIntervalSince1970:time];
    //实例化一个NSDateFormatter对象
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *currentDateStr = [dateFormatter stringFromDate: detaildate];
    return currentDateStr;
}

- (void)dealloc {
    //移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"stepChanged" object:@"toSport"];
}

#pragma mark 日历禁用数据源
- (void)getDisabledDataSourceByDate:(NSDate *)date dayCount:(NSString *)dayCount {
    NSTimeInterval a=[date timeIntervalSince1970];
    int timeStr = [[NSString stringWithFormat:@"%0.f", a] intValue];
    NSNumber *num = [NSNumber numberWithInt:timeStr];
    NSNumber *days = [NSNumber numberWithInt:[dayCount intValue]];
    
    self.checkToken = YES;
    [self getBasicHeader];
    NSMutableDictionary *info = [NSMutableDictionary new];
    [info setValue:num forKey:@"startDate"];
    [info setValue:days forKey:@"days"];

    
     [SSNetworkRequest getRequest:apiGetRecordDate params:info success:^(id responseObj) {
        
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            NSLog(@"查询到的记录的运动日期：%@",responseObj);
            NSArray *arr = responseObj[@"data"];
       
            
            
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadCalendar" object:arr];
        
            /*
            for (NSDictionary *dict in arr) {
                NSString *dataStr = [self convertTimeToTimeStringWithTime:dict[@"Date"]];
                NSLog(@"记录的时间为：%@", dataStr);
            }*/
        
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
           
         
        }else{
            //数据请求失败
            NSLog(@"数据请求失败");
        }
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.calendar removeWindow];
    [super viewDidDisappear:animated];
}

@end
