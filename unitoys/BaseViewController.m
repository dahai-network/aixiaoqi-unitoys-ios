//
//  BaseViewController.m
//  CloudEgg
//
//  Created by ququ-iOS on 15/12/22.
//  Copyright © 2015年 ququ-iOS. All rights reserved.
//

#import "BaseViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import "ContactModel.h"
#import "AddressBookManager.h"
#import "WXApi.h"
#import "UIBarButtonItem+Extension.h"

@implementation BaseViewController

@synthesize params;
@synthesize headers;

-(void)viewDidLoad
{
    [super viewDidLoad];
    //左边按钮
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithImage:[[UIImage imageNamed:@"btn_back"] imageWithRenderingMode:/*去除渲染效果*/UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonAction)];
}

- (void)leftButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark-----设置左边按钮
-(void)setLeftButton:(id)LeftButton{
    NSMutableDictionary *textAttrs = [NSMutableDictionary dictionary];
    textAttrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
    textAttrs[NSFontAttributeName] = [UIFont systemFontOfSize:16.5];
    if ([LeftButton isKindOfClass:[UIImage class]]) {
        self.navigationItem.leftBarButtonItem=[UIBarButtonItem itemWithTarget:self action:@selector(leftButtonClick) image:LeftButton highImage:LeftButton];
        [self.navigationItem.leftBarButtonItem setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
        return;
    }
    if ([LeftButton isKindOfClass:[NSString class]]) {
        self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:LeftButton style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonClick)];
        [self.navigationItem.leftBarButtonItem setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
        return;
    }
}

#pragma mark-----点击左按钮出发事情
-(void)leftButtonClick{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark-----设置右边按钮
-(void)setRightButton:(id)rightButton{
    NSMutableDictionary *textAttrs = [NSMutableDictionary dictionary];
    textAttrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
    textAttrs[NSFontAttributeName] = [UIFont systemFontOfSize:16.5];
    if ([rightButton isKindOfClass:[UIImage class]]) {
        self.navigationItem.rightBarButtonItem=[UIBarButtonItem itemWithTarget:self action:@selector(rightButtonClick) image:rightButton highImage:rightButton];
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
    }
    if ([rightButton isKindOfClass:[NSString class]]) {
        self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:rightButton style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonClick)];
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
    }
}

#pragma mark-----点击右按钮出发事情
-(void)rightButtonClick{
    
    
}

- (UIStatusBarStyle)preferredStatusBarStyle

{
    
    return UIStatusBarStyleLightContent;
    
}

-(NSString*)convertNull:(id)object{
    
    // 转换空串
    
    if ([object isEqual:[NSNull null]]) {
        return @"-";
    }
    else if ([object isKindOfClass:[NSNull class]])
    {
        return @"-";
    }
    else if (object==nil){
        return @"无";
    }
    return object;
    
}

- (NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (NSString *)md50:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

-(void)getBasicHeader
{
    //进行Header的构造，partner，Expries，Sign，TOKEN
    self.headers = [[NSMutableDictionary alloc] init];
    [self.headers setObject:@"2006808" forKey:@"partner"];
    
//    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
//    NSInteger a=[dat timeIntervalSince1970];
//    NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
    NSString *timestemp = @"1471316792";
    
    [self.headers setObject:timestemp forKey:@"expires"];
    
    timestemp = [NSString stringWithFormat:@"2006808%@BAS123!@#FD1A56K",timestemp];
    
    [self.headers setObject:[self md5:timestemp] forKey:@"sign"];
    
    if (self.checkToken) {
        NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
        if (userdata) {
            [self.headers setObject:[userdata objectForKey:@"Token"] forKey:@"TOKEN"];
        }
    }
    
}

-(void)getBasicParam
{
    self.params = [[NSMutableDictionary alloc] init];
    
    [self.params setObject:@"2006808" forKey:@"partner"];
    
//    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
//    NSInteger a=[dat timeIntervalSince1970];
//    NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
    
    NSString *timestemp = @"1471316792";
    
    [self.params setObject:timestemp forKey:@"expires"];
    
    timestemp = [NSString stringWithFormat:@"2006808%@BAS123!@#FD1A56K",timestemp];
    
    NSLog(@"md5 key:%@",[self md5:timestemp]);
    
    [self.params setObject:[self md5:timestemp] forKey:@"sign"];
    
    /*
    if (self.checkToken) {
        NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
        if (userdata) {
            [self.params setObject:[userdata objectForKey:@"Token"] forKey:@"TOKEN"];
        }
        
    }*/
    
    
}

- (NSString *)getParamStr
{

    if (self.checkToken) {
        [self getBasicHeader];
        return [NSString stringWithFormat:@"?partner=%@&expires=%@&sign=%@",[headers objectForKey:@"partner"],[headers objectForKey:@"expires"],[headers objectForKey:@"sign"]];

    }else{
        [self getBasicParam];
        return [NSString stringWithFormat:@"?partner=%@&expires=%@&sign=%@",[params objectForKey:@"partner"],[params objectForKey:@"expires"],[params objectForKey:@"sign"]];

    }
    /*
    if(self.checkToken){
        return [NSString stringWithFormat:@"?partner=%@&expires=%@&sign=%@&Token=%@",[params objectForKey:@"partner"],[params objectForKey:@"expires"],[params objectForKey:@"sign"],[params objectForKey:@"Token"]];
    }else*/
    
    
}

-(void)setExtraCellLineHidden: (UITableView *)tableView

{
    
    UIView *view = [UIView new];
    
    view.backgroundColor = [UIColor clearColor];
    
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [tableView setTableFooterView:view];
    
    [tableView setBackgroundColor:[UIColor colorWithRed:225/255.0 green:225/255.0 blue:225/255.0 alpha:1]];
     
}

- (NSString *)timeWithTimeIntervalString:(NSString *)timeString :(NSString*)format
{
    // 格式化时间
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone localTimeZone];
    
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    //    [formatter setDateFormat:@"yyyy/MM/dd HH:mm"];
    [formatter setDateFormat:format];
    
    // 毫秒值转化为秒
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:[timeString doubleValue]/ 1000.0];
    NSString* dateString = [formatter stringFromDate:date];
    return dateString;
}

- (NSString *)compareCurrentTimeString:(NSString *)compareDateString
{
    NSTimeInterval second = compareDateString.longLongValue;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
    return [self compareCurrentTime:date];
}

-(NSString *) compareCurrentTime:(NSDate*) compareDate
//
{
    NSTimeInterval  timeInterval = [compareDate timeIntervalSinceNow];
    timeInterval = -timeInterval;
    long temp = 0;
    NSString *result;
    if (timeInterval < 60) {
        result = [NSString stringWithFormat:@"刚刚"];
    }
    else if((temp = timeInterval/60) <60){
        result = [NSString stringWithFormat:@"%ld分前",temp];
    }
    
    else if((temp = temp/60) <24){
        result = [NSString stringWithFormat:@"%ld小时前",temp];
    }
    
    else if((temp = temp/24) <30){
        result = [NSString stringWithFormat:@"%ld天前",temp];
    }
    
    else{
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        formatter.timeZone = [NSTimeZone localTimeZone];
        
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDateFormat:@"yyyy/MM/dd"];
        
        result = [formatter stringFromDate:compareDate];
        //直接输出时间
    }
    /* if((temp = temp/30) <12){
     result = [NSString stringWithFormat:@"%ld月前",temp];
     }
     else{
     temp = temp/12;
     result = [NSString stringWithFormat:@"%ld年前",temp];
     }*/
    
    return  result;
}

-(NSString *) formatTime:(NSDate*) formatDate {
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone localTimeZone];
    NSLog(@"当前时区：%@", formatter.timeZone);
    
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"yyyy-MM-dd HH:MM:ss"];
    
    return  [formatter stringFromDate:formatDate];
}

- (NSDate*)convertDate :(NSString *)timestamp {
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"yyyyMMddHHMMss"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[timestamp doubleValue]];
    return date;
}

- (NSString *)convertDateWithString:(NSString *)dateString {
    NSTimeInterval time=[dateString doubleValue];//因为时差问题要加8小时 == 28800 sec?
    NSDate *detaildate=[NSDate dateWithTimeIntervalSince1970:time];
    //实例化一个NSDateFormatter对象
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone localTimeZone];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *currentDateStr = [dateFormatter stringFromDate: detaildate];
    return currentDateStr;
}

- (void)dj_alertAction:(UIViewController *)controller alertTitle:(NSString *)alertTitle actionTitle:(NSString *)actionTitle message:(NSString *)message alertAction:(void (^)())alertAction {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:alertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        alertAction();
    }];
    [alertVC addAction:cancelAction];
    [alertVC addAction:certailAction];
    [controller presentViewController:alertVC animated:YES completion:nil];
}

- (void)dj_alertAction:(UIViewController *)controller alertTitle:(NSString *)alertTitle leftActionTitle:(NSString *)leftActionTitle rightActionTitle:(NSString *)rightActionTitle message:(NSString *)message leftAlertAction:(void (^)())leftAlertAction rightAlertAction:(void (^)())rightAlertAction {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:alertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:leftActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        leftAlertAction();
    }];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:rightActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        rightAlertAction();
    }];
    [alertVC addAction:cancelAction];
    [alertVC addAction:certailAction];
    [controller presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark 非空判断
- (BOOL)isBlankString:(NSString *)string {
    if (string == nil || string == NULL ) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}

//短信不显示组名
- (NSString *)checkLinkNameWithPhoneStrNoGroupName:(NSString *)phoneStr
{
    NSString *linkName;
    if ([phoneStr containsString:@"-"]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@" "]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@"+86"]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"+86" withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@"#"]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"#" withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@","]) {
        NSArray *arr = [phoneStr componentsSeparatedByString:@","];
        for (NSString *str in arr) {
            NSString *string;
            string = [self checkNameWithNumberNoGroupName:str];
            if (linkName) {
                linkName = [NSString stringWithFormat:@"%@,%@", linkName, string];
            } else {
                linkName = string;
            }
        }
    } else {
        linkName = [self checkNameWithNumberNoGroupName:phoneStr];
        return linkName;
    }
    return linkName;

}

- (NSString *)checkLinkNameWithPhoneStr:(NSString *)phoneStr {
    NSString *linkName;
    if ([phoneStr containsString:@"-"]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@" "]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@"+86"]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"+86" withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@"#"]) {
        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"#" withString:@""];
        phoneStr = newStr;
    }
    if ([phoneStr containsString:@","]) {
        NSArray *arr = [phoneStr componentsSeparatedByString:@","];
        for (NSString *str in arr) {
            NSString *string;
            string = [self checkNameWithNumber:str];
            if (linkName) {
                linkName = [NSString stringWithFormat:@"%@,%@", linkName, string];
            } else {
                linkName = string;
            }
        }
    } else {
        linkName = [self checkNameWithNumber:phoneStr];
        return linkName;
    }
    return linkName;
}

//短信不显示组名
- (NSString *)checkNameWithNumberNoGroupName:(NSString *)number
{
    ContactModel *tempModel;
    NSString *linkName = number;
    for (ContactModel *model in [AddressBookManager shareManager].dataArr) {
        tempModel = model;
        if ([model.phoneNumber containsString:@"-"]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
        }
        if ([model.phoneNumber containsString:@" "]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
        }
        if ([model.phoneNumber containsString:@"+86"]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"+86" withString:@""];
        }
        if ([model.phoneNumber containsString:@"#"]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"#" withString:@""];
        }
        if ([number isEqualToString:[NSString stringWithFormat:@"%@", tempModel.phoneNumber]]) {
            linkName = tempModel.name;
            return linkName;
        }
        if ([number isEqualToString:@"anonymous"]) {
            linkName = @"未知";
            return linkName;
        }
    }
    return linkName;
}

- (NSString *)checkNameWithNumber:(NSString *)number {
    ContactModel *tempModel;
    NSString *linkName = number;
    for (ContactModel *model in [AddressBookManager shareManager].dataArr) {
        tempModel = model;
        if ([model.phoneNumber containsString:@"-"]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
        }
        if ([model.phoneNumber containsString:@" "]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
        }
        if ([model.phoneNumber containsString:@"+86"]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"+86" withString:@""];
        }
        if ([model.phoneNumber containsString:@"#"]) {
            tempModel.phoneNumber = [model.phoneNumber stringByReplacingOccurrencesOfString:@"#" withString:@""];
        }
        if ([model.phoneNumber containsString:@","]) {
            NSArray *phoneArr = [model.phoneNumber componentsSeparatedByString:@","];
            for (NSString *phoneStr in phoneArr) {
                if ([number isEqualToString:phoneStr]) {
                    linkName = tempModel.name;
                    break;
                }
            }
        }
        if ([number isEqualToString:[NSString stringWithFormat:@"%@", tempModel.phoneNumber]]) {
            linkName = tempModel.name;
            return linkName;
        }
        if ([number isEqualToString:@"anonymous"]) {
            linkName = @"未知";
            return linkName;
        }
    }
    return linkName;
}

- (BOOL)isWXAppInstalled
{
    // 1.判断是否安装微信
    NSLog(@"%d",[WXApi isWXAppInstalled]);
    if (![WXApi isWXAppInstalled]) {
        HUDNormal(@"您尚未安装\"微信App\",请先安装后再返回支付");
        return NO;
    }
    
    // 2.判断微信的版本是否支持最新Api
    if (![WXApi isWXAppSupportApi]) {
        HUDNormal(@"您微信当前版本不支持此功能,请先升级微信应用");
        return NO;
    }
    return YES;
}

@end
