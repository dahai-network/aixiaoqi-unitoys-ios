//
//  SportDataViewController.h
//  unitoys
//
//  Created by sumars on 16/11/24.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"
#import "LineProgressView.h"
#import "FDCalendar.h"

#import "FDCalendarItem.h"  //引用数据源声明

@class FDCalendar;  //日历选择组件

@interface SportDataViewController : BaseTableController<FDCalendarDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnBarTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblKM;     //运动距离
@property (weak, nonatomic) IBOutlet UILabel *lblKcal;   //消耗千卡
@property (weak, nonatomic) IBOutlet UILabel *lblTarget; //目标
@property (weak, nonatomic) IBOutlet UILabel *lblDayout; //当日步数
@property (nonatomic, assign) int currentDayTotalStep;//当日总步数

@property (weak, nonatomic) IBOutlet LineProgressView *lpvPercent; //完成比例，仪表盘组件
@property (weak, nonatomic) IBOutlet UIView *vwSumary;  //表头视图，为了动态计算，加入属性

@property (weak, nonatomic) FDCalendar *calendar;

@property (strong,nonatomic) NSMutableArray *arrSportData; //运动数据列表
@property (readwrite)  NSDate *currentDate;                 //是否用字符类型你定

- (void) setPercent :(int)value :(int)maxValue;   //设置完成的比例

- (IBAction)choiceDate:(id)sender;   //选择数据日期
- (IBAction)showProfile:(id)sender;  //显示个人数据






@end
