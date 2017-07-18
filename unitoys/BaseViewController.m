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
#import "BrowserViewController.h"
#import "BlueToothDataManager.h"
#import "UNNetWorkStatuManager.h"

@implementation BaseViewController

@synthesize params;
@synthesize headers;

-(void)viewDidLoad
{
    [super viewDidLoad];
    //左边按钮
    if ([self isShowLeftButton]) {
            self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithImage:[[UIImage imageNamed:@"btn_back"] imageWithRenderingMode:/*去除渲染效果*/UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonAction)];
    }
//    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithImage:[[UIImage imageNamed:@"btn_back"] imageWithRenderingMode:/*去除渲染效果*/UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonAction)];
}

-(void)setLeftView{
    UIButton *CustomView=[[UIButton alloc]initWithFrame:CGRectMake(0, 10, 100, 30)];
    
    UIButton * backItem = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 56, 30)];
    [backItem setImage:[UIImage imageNamed:@"btn_back"] forState:UIControlStateNormal];
    [backItem setImageEdgeInsets:UIEdgeInsetsMake(-2, 0, 0, 0)];
    [backItem setTitle:@"返回" forState:UIControlStateNormal];
    [backItem setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
    backItem.titleLabel.font = [UIFont systemFontOfSize:16.5];
    [backItem setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backItem addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [CustomView addSubview:backItem];
    
    UIButton * closeItem = [[UIButton alloc]initWithFrame:CGRectMake(backItem.un_width, 0, 44, 30)];
    [closeItem setTitle:@"关闭" forState:UIControlStateNormal];
    closeItem.titleLabel.font = [UIFont systemFontOfSize:16.5];
    [closeItem setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeItem addTarget:self action:@selector(clickedCloseItem:) forControlEvents:UIControlEventTouchUpInside];
    closeItem.hidden = YES;
    self.closeItem = closeItem;
    [CustomView addSubview:closeItem];
    
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithCustomView:CustomView];
    
}

#pragma mark------返回
-(void)back{
    
}

#pragma mark - clickedCloseItem
- (void)clickedCloseItem:(UIButton *)btn{
    [self.navigationController popViewControllerAnimated:YES];
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

- (BOOL)isShowLeftButton
{
    return YES;
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
    
    // 当前软件的版本号（从Info.plist中获得）
    NSString *key = @"CFBundleShortVersionString";
    NSString *versionNumberStr = [NSBundle mainBundle].infoDictionary[key];
    [self.headers setObject:versionNumberStr forKey:@"Version"];
    
    //附加信息
    NSString *terminalStr = @"iOS";
    [self.headers setObject:terminalStr forKey:@"Terminal"];
    
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
    
    // 当前软件的版本号（从Info.plist中获得）
    NSString *key = @"CFBundleShortVersionString";
    NSString *versionNumberStr = [NSBundle mainBundle].infoDictionary[key];
    [self.headers setObject:versionNumberStr forKey:@"Version"];
    
    //附加信息
    NSString *terminalStr = @"iOS";
    [self.headers setObject:terminalStr forKey:@"Terminal"];
    
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
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:INTERNATIONALSTRING(alertTitle) message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"取消") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(actionTitle) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        alertAction();
    }];
    [alertVC addAction:cancelAction];
    [alertVC addAction:certailAction];
    [controller presentViewController:alertVC animated:YES completion:nil];
}

- (void)dj_alertAction:(UIViewController *)controller alertTitle:(NSString *)alertTitle leftActionTitle:(NSString *)leftActionTitle rightActionTitle:(NSString *)rightActionTitle message:(NSString *)message leftAlertAction:(void (^)())leftAlertAction rightAlertAction:(void (^)())rightAlertAction {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:INTERNATIONALSTRING(alertTitle) message:INTERNATIONALSTRING(message) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(leftActionTitle) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        leftAlertAction();
    }];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(rightActionTitle) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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

//短信去除重复组名
- (NSString *)checkLinkNameWithPhoneStrMergeGroupName:(NSString *)phoneStr {
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
                //防止长号包含短号
                if (![str containsString:string]) {
                    //去除重复组名
                    if (![linkName containsString:string]) {
                        linkName = [NSString stringWithFormat:@"%@,%@", linkName, string];
                    }
                }else{
                    linkName = [NSString stringWithFormat:@"%@,%@", linkName, string];
                }
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
//    if ([phoneStr containsString:@"-"]) {
//        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
//        phoneStr = newStr;
//    }
//    if ([phoneStr containsString:@" "]) {
//        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
//        phoneStr = newStr;
//    }
//    if ([phoneStr containsString:@"+86"]) {
//        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"+86" withString:@""];
//        phoneStr = newStr;
//    }
//    if ([phoneStr containsString:@"#"]) {
//        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"#" withString:@""];
//        phoneStr = newStr;
//    }
//    if ([phoneStr containsString:@"("]) {
//        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@"(" withString:@""];
//        phoneStr = newStr;
//    }
//    if ([phoneStr containsString:@")"]) {
//        NSString *newStr = [phoneStr stringByReplacingOccurrencesOfString:@")" withString:@""];
//        phoneStr = newStr;
//    }
    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"+86" withString:@""];
    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"#" withString:@""];
    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@"(" withString:@""];
    phoneStr = [phoneStr stringByReplacingOccurrencesOfString:@")" withString:@""];
    
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

- (ContactModel *)checkContactModelWithPhoneStr:(NSString *)phoneStr
{
    ContactModel *model;
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
        phoneStr = arr.firstObject;
    }
    model = [self checkModelWithNumber:phoneStr];
    return model;
}

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

- (ContactModel *)checkModelWithNumber:(NSString *)number
{
    ContactModel *tempModel;
    ContactModel *resultModel;
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
                    resultModel = tempModel;
                    break;
                }
            }
        }
        if ([number isEqualToString:[NSString stringWithFormat:@"%@", tempModel.phoneNumber]]) {
            resultModel = tempModel;
            return resultModel;
        }
    }
    return resultModel;
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

- (void)setStatuesLabelTextWithLabel:(UILabel *)label String:(NSString *)string {
    if ([string isEqualToString:HOMESTATUETITLE_NETWORKCANNOTUSE]) {
        label.text = @"当前网络不可用";
    } else if ([string isEqualToString:HOMESTATUETITLE_BLNOTOPEN]) {
        label.text = @"手机蓝牙未开启";
    } else if ([string isEqualToString:HOMESTATUETITLE_NOTCONNECTED]) {
        label.text = @"未连接设备";
    } else if ([string isEqualToString:HOMESTATUETITLE_READCARDFAIL]) {
        label.text = @"读取“设备”内卡失败";
    } else if ([string isEqualToString:HOMESTATUETITLE_REGISTING]) {
        label.text = @"电话卡正在连接运营商，请稍后!";
    } else if ([string isEqualToString:HOMESTATUETITLE_READCARDFAIL]) {
        label.text = @"电话卡注册到运营商失败！";
    } else if ([string isEqualToString:HOMESTATUETITLE_NOTSERVICE]) {
        label.text = @"通话短信服务已关闭";
    } else {
        label.text = string;
    }
}

#pragma mark 是否显示状态栏
- (BOOL)isNeedToShowBLEStatue {
    if (([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NETWORKCANNOTUSE] || [[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_BLNOTOPEN] || [[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTCONNECTED] || [[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_READCARDFAIL] || [[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOSIGNAL] || [[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_REGISTING] || [[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTSERVICE]) && [BlueToothDataManager shareManager].isShowStatuesView) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark 拨打电话的时候提示
- (BOOL)checkBLEStatueAndAlert {
    if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NETWORKCANNOTUSE]) {
        HUDNormal(@"当前网络不可用，请检查你的网络设置！")
        return YES;
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTBOUND]) {
        HUDNormal(@"请先绑定爱小器智能通讯硬件，才可使用通话短信功能！")
        return YES;
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_BLNOTOPEN]) {
        HUDNormal(@"手机蓝牙未打开，请先开启！")
        return YES;
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTCONNECTED]) {
        HUDNormal(@"未连上您的设备，请检查它是否在附近或有电！")
        return YES;
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTSERVICE]) {
        HUDNormal(@"您关闭了通话短信服务，请在“我的”页面重新开启该服务！")
        return YES;
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTINSERTCARD]) {
        HUDNormal(@"未检测到设备内有电话卡，请确认是否插卡或插卡方向是否有误！")
        return YES;
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_AIXIAOQICARD]) {
        HUDNormal(@"您设备内为爱小器国际上网卡，不支持通话和短信服务！")
        return YES;
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_READCARDFAIL]) {
        HUDNormal(@"读取设备内电话卡失败，请确认您插入的电话卡是否有效！")
        return YES;
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_REGISTING]) {
        HUDNormal(@"设备内电话卡正在注册到运营商，请稍候！")
        return YES;
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOSIGNAL]) {
        HUDNormal(@"设备内电话卡注册到运营商失败，请检查您的当前网络是否稳定！")
        return YES;
    } else {
        return NO;
    }
}

- (void)showAlertMessageToCall {
    if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NETWORKCANNOTUSE]) {
        HUDNormal(@"当前网络不可用，请检查你的网络设置！")
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTBOUND]) {
        HUDNormal(@"请先绑定爱小器智能通讯硬件，才可使用通话短信功能！")
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_BLNOTOPEN]) {
        HUDNormal(@"手机蓝牙未打开，请先开启！")
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTCONNECTED]) {
        HUDNormal(@"未连上您的设备，请检查它是否在附近或有电！")
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTSERVICE]) {
        HUDNormal(@"您关闭了通话短信服务，请在“我的”页面重新开启该服务！")
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTINSERTCARD]) {
        HUDNormal(@"未检测到设备内有电话卡，请确认是否插卡或插卡方向是否有误！")
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_AIXIAOQICARD]) {
        HUDNormal(@"您设备内为爱小器国际上网卡，不支持通话和短信服务！")
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_READCARDFAIL]) {
        HUDNormal(@"读取设备内电话卡失败，请确认您插入的电话卡是否有效！")
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_REGISTING]) {
        HUDNormal(@"设备内电话卡正在注册到运营商，请稍候！")
    } else if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOSIGNAL]) {
        HUDNormal(@"设备内电话卡注册到运营商失败，请检查您的当前网络是否稳定！")
    } else {
        HUDNormal(INTERNATIONALSTRING(@"设备内sim卡未注册或已掉线"))
    }
}

- (void)changeBleStatue {
    if ([UNNetWorkStatuManager shareManager].currentStatu == NotReachable) {
        //无网络
        [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NETWORKCANNOTUSE;
    } else {
        if (![BlueToothDataManager shareManager].isBounded) {
            //未绑定
            [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTBOUND;
        } else {
            if (![BlueToothDataManager shareManager].isOpened) {
                //蓝牙未开
                [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_BLNOTOPEN;
            } else {
                if (![BlueToothDataManager shareManager].isConnected) {
                    //未连接
                    [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTCONNECTED;
                } else {
                    if ([BlueToothDataManager shareManager].isLbeConnecting) {
                        //连接中
                        [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_CONNECTING;
                    } else {
                        if ([[BlueToothDataManager shareManager].operatorType intValue] == 4) {
                            //爱小器卡
                            [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_AIXIAOQICARD;
                        } else {
                            if (![[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"offsetStatue"] isEqualToString:@"on"]) {
                                if ([[BlueToothDataManager shareManager].operatorType intValue] == 5) {
                                    //未插卡
                                    [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTINSERTCARD;
                                } else {
                                    if ([[BlueToothDataManager shareManager].operatorType isEqualToString:@"0"]) {
                                        //读取卡失败
                                        [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_READCARDFAIL;
                                    } else {
                                        if ([BlueToothDataManager shareManager].isBeingRegisting) {
                                            //注册中
                                            [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_REGISTING;
                                        } else {
                                            if ([BlueToothDataManager shareManager].isRegisted) {
                                                //信号强
                                                [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_SIGNALSTRONG;
                                            } else {
                                                if ([BlueToothDataManager shareManager].isRegistedFail) {
                                                    //注册失败
                                                    [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOSIGNAL;
                                                } else {
                                                    //默认
                                                    [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_REGISTING;
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                //服务关闭
                                [BlueToothDataManager shareManager].statuesTitleString = HOMESTATUETITLE_NOTSERVICE;
                            }
                        }
                    }
                }
            }
        }
    }
}

@end
