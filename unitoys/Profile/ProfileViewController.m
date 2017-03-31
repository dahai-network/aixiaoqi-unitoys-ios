//
//  ProfileViewController.m
//  unitoys
//
//  Created by sumars on 16/11/3.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "ProfileViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "SetValueViewController.h"

#import "UIImageView+WebCache.h"
#import "BlueToothDataManager.h"

#import "AFNetworking.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    // Do any additional setup after loading the view.
    
//    self.tableView.scrollEnabled = NO;
    
    UIView *valueView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    valueView.backgroundColor = [UIColor colorWithRed:32/255 green:34/255 blue:42/255 alpha:0.2];
    
    UIPickerView *pickerview = [[UIPickerView alloc] initWithFrame: CGRectMake(0,self.view.bounds.size.height-210,self.view.bounds.size.width,105)];
    [pickerview setBackgroundColor:[UIColor whiteColor]];
    [valueView addSubview:pickerview];
    self.pickerView = pickerview;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMinY(pickerview.frame) - 41, self.view.bounds.size.width, 40)];
    titleLabel.backgroundColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [valueView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UIButton *btnOK = [[UIButton alloc] initWithFrame:CGRectMake(0,CGRectGetMaxY(pickerview.frame) + 3, self.view.bounds.size.width, 35)];
    btnOK.hidden = NO;
    [btnOK setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnOK setTitle:INTERNATIONALSTRING(@"确定") forState:UIControlStateNormal];
    [btnOK setBackgroundColor:[UIColor whiteColor]];
    
    [btnOK addTarget:self action:@selector(selectValue) forControlEvents:UIControlEventTouchUpInside];
    
    [valueView addSubview:btnOK];
    
    pickerview.delegate = self;
    pickerview.dataSource = self;
    
    [self.view addSubview:valueView];
    valueView.hidden = YES;
    self.valueView = valueView;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.valueView addGestureRecognizer:tap];
    
    self.pickerType = 1;
    
    self.arrSource = self.arrSex;
    
    self.arrSex=@[INTERNATIONALSTRING(@"男"),INTERNATIONALSTRING(@"女")];
    
    NSMutableArray *arrTemp = [[NSMutableArray alloc] init];
    for (int i=0;i<=230;i++) {
        [arrTemp addObject:[NSString stringWithFormat:@"%dcm",i]];
    }
    
    self.arrHeight = [[NSArray alloc] initWithArray:arrTemp];
    
    arrTemp = [[NSMutableArray alloc] init];
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY年MM月"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    self.yearStr = [[dateString substringWithRange:NSMakeRange(0, 4)] intValue];
    for (int i=1916;i<=self.yearStr;i++) {
        [arrTemp addObject:[NSString stringWithFormat:@"%d年",i]];
    }
    self.arrAgeYear = [[NSArray alloc] initWithArray:arrTemp];
    
    arrTemp = [[NSMutableArray alloc] init];
    self.monthStr = [[dateString substringWithRange:NSMakeRange(5, 2)] intValue];
    for (int i = 1; i < 13; i++) {
        [arrTemp addObject:[NSString stringWithFormat:@"%d月", i]];
    }
    self.arrAgeMonth = [[NSArray alloc] initWithArray:arrTemp];
    
    
    arrTemp = [[NSMutableArray alloc] init];
    for (int i=0;i<=110;i++) {
        [arrTemp addObject:[NSString stringWithFormat:@"%dkg",i]];
    }
    
    self.arrWeight = [[NSArray alloc] initWithArray:arrTemp];
    
    arrTemp = [[NSMutableArray alloc] init];
    
    for (int i=0;i<=31000;i=i+1000) {
        [arrTemp addObject:[NSString stringWithFormat:@"%d%@",i, INTERNATIONALSTRING(@"步")]];
    }
    
    self.arrTarget = [[NSArray alloc] initWithArray:arrTemp];
    
    [self loadUserInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setValue:) name:@"setValue" object:nil];
}

- (void)tapAction {
    if (!self.valueView.hidden) {
        self.valueView.hidden = YES;
        self.tableView.scrollEnabled = self.valueView.hidden;
    }
}

- (void)setValue :(NSNotification *)notification {

    self.checkToken = YES;
    //    ;
    //
    NSString *str = notification.object;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:str,@"NickName", nil];
    NSLog(@"%@", params);
    NSMutableDictionary *dic = [NSMutableDictionary new];
    [dic setObject:str forKey:@"NickName"];
    
//    [self.dicInfo setObject:str forKey:@"NickName"];
    [self.dicInfo setObject:str forKey:@"NickName"];
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    
    [self.valueView setHidden:YES];
    self.tableView.scrollEnabled = self.valueView.hidden;
    [SSNetworkRequest postRequest:apiUpdateUserInfo params:dic success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            NSLog(@"查询到的用户数据：%@",responseObj);
            
//            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            HUDNormal(responseObj[@"msg"])
            
            [[NSUserDefaults standardUserDefaults] setObject:self.dicInfo forKey:@"userData"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self loadUserInfo];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        [self.navigationController popViewControllerAnimated:YES];
        
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)selectValue {
    //
    
    self.checkToken = YES;
    //    ;
    //
    NSDictionary *params; /*[[NSDictionary alloc] initWithObjectsAndKeys:[[UIDevice currentDevice] systemVersion],@"Version",[[UIDevice currentDevice] model],@"Model",self.contentFeedback.text,@"Info", nil];*/
    NSString *aValue;
    NSString *avalue1;
    NSString *timeString;
    NSString *convertTime;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date;
    
    switch (self.pickerType) {
        case 1:
            //
            if ([self.pickerView selectedRowInComponent:0]==0) {
                params = [[NSDictionary alloc] initWithObjectsAndKeys:@"0",@"Sex", nil];
                [self.dicInfo setObject:@"0" forKey:@"Sex"];
            } else {
                params = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"Sex", nil];
                [self.dicInfo setObject:@"1" forKey:@"Sex"];
            }
            
            break;
        case 2:
            //
            
            aValue= [[self.arrAgeYear objectAtIndex:[self.pickerView selectedRowInComponent:0]] stringByReplacingOccurrencesOfString:@"年" withString:@""];
            avalue1 = [[self.arrAgeMonth objectAtIndex:[self.pickerView selectedRowInComponent:1]] stringByReplacingOccurrencesOfString:@"月" withString:@""];
            timeString = [NSString stringWithFormat:@"%@-%@-01 00:00:00", aValue, avalue1];
            date = [formatter dateFromString:timeString];
            convertTime = [NSString stringWithFormat:@"%ld", (long)[date timeIntervalSince1970] + 8*3600];
            NSLog(@"timeSp:%@",convertTime); //时间戳的值
            
            params = [[NSDictionary alloc] initWithObjectsAndKeys:convertTime,@"Birthday", nil];
            [self.dicInfo setObject:aValue forKey:@"year"];
            [self.dicInfo setObject:avalue1 forKey:@"month"];
            [self.dicInfo setObject:convertTime forKey:@"Birthday"];
            break;
        case 3:
            //
            
            aValue= [[self.arrHeight objectAtIndex:[self.pickerView selectedRowInComponent:0]] stringByReplacingOccurrencesOfString:@"cm" withString:@""];
            
            params = [[NSDictionary alloc] initWithObjectsAndKeys:aValue,@"Height", nil];
            
            [self.dicInfo setObject:aValue forKey:@"Height"];
            break;
        case 4:
            //
            
            aValue= [[self.arrWeight objectAtIndex:[self.pickerView selectedRowInComponent:0]] stringByReplacingOccurrencesOfString:@"kg" withString:@""];
            
            params = [[NSDictionary alloc] initWithObjectsAndKeys:aValue,@"Weight", nil];
            
            [self.dicInfo setObject:aValue forKey:@"Weight"];
            
            break;
        case 5:
            //
            
            aValue= [[self.arrTarget objectAtIndex:[self.pickerView selectedRowInComponent:0]] stringByReplacingOccurrencesOfString:INTERNATIONALSTRING(@"步") withString:@""];
            
            params = [[NSDictionary alloc] initWithObjectsAndKeys:aValue,@"MovingTarget", nil];
            
            [self.dicInfo setObject:aValue forKey:@"MovingTarget"];
            
            break;
            
        default:
            break;
    }
    
    [self getBasicHeader];
    NSLog(@"表演头：%@",self.headers);
    
    [self.valueView setHidden:YES];
    self.tableView.scrollEnabled = self.valueView.hidden;
    [SSNetworkRequest postRequest:apiUpdateUserInfo params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            
            NSLog(@"查询到的用户数据：%@",responseObj);
            
//            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            HUDNormal(responseObj[@"msg"])
            
            [[NSUserDefaults standardUserDefaults] setObject:self.dicInfo forKey:@"userData"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self loadUserInfo];
            
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
    
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

- (void)loadUserInfo{
    NSDictionary *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    
    [self.ivUserHead sd_setImageWithURL:[NSURL URLWithString:[userData objectForKey:@"UserHead"]]];
    
    self.lblName.text = [userData objectForKey:@"NickName"];
    
    if ([[userData objectForKey:@"Sex"] intValue]==0) {
        self.lblSex.text = INTERNATIONALSTRING(@"男");
    }else{
        self.lblSex.text = INTERNATIONALSTRING(@"女");
    }
    if (userData[@"Birthday"]) {
        self.lblAge.text = [[self timeWithTimeIntervalString:userData[@"Birthday"]] substringWithRange:NSMakeRange(0, 8)];
    } else {
        if (userData[@"year"] && userData[@"month"]) {
            self.lblAge.text = [NSString stringWithFormat:@"%@年%@月",[userData objectForKey:@"year"], [userData objectForKey:@"month"]];
        } else {
            self.lblAge.text = [NSString stringWithFormat:@"%d年%d月", self.yearStr, self.monthStr];
        }
    }
    
    self.lblHeight.text = [NSString stringWithFormat:@"%@cm",[userData objectForKey:@"Height"]];
    self.lblWeight.text = [NSString stringWithFormat:@"%@kg",[userData objectForKey:@"Weight"]];
    
    self.lblTarget.text = [NSString stringWithFormat:@"%@%@",[userData objectForKey:@"MovingTarget"], INTERNATIONALSTRING(@"步")];
    [BlueToothDataManager shareManager].movingTarget = [userData objectForKey:@"MovingTarget"];
    [self calcBMI];
    
    self.dicInfo = [[NSMutableDictionary alloc] initWithDictionary:userData];
    
    
    
}

- (NSString *)timeWithTimeIntervalString:(NSString *)timeString
{
    // 格式化时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"shanghai"];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"yyyy年MM月dd日 HH:mm"];
    
    // 毫秒值转化为秒
    NSTimeInterval time=[timeString doubleValue];//因为时差问题要加8小时 == 28800 sec?
    NSDate *date=[NSDate dateWithTimeIntervalSince1970:time];
    NSString* dateString = [formatter stringFromDate:date];
    
    return dateString;
}

- (void)calcBMI{
    
    if ([self.lblHeight.text length]>0) {
        if ([self.lblWeight.text floatValue] > 30) {
            self.lblBmi.text = [NSString stringWithFormat:@"%.2f",[self.lblWeight.text floatValue]/[self.lblHeight.text intValue]/[self.lblHeight.text intValue]*10000];
        } else {
            NSString *weight = @"30";
            self.lblBmi.text = [NSString stringWithFormat:@"%.2f",[weight floatValue]/[self.lblHeight.text intValue]/[self.lblHeight.text intValue]*10000];
        }
    }else{
        self.lblBmi.text = @"";
    }
    
    
}

- (void)loadNewHead{
    UIActionSheet *choiceSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:INTERNATIONALSTRING(@"取消")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:INTERNATIONALSTRING(@"拍照"), INTERNATIONALSTRING(@"从相册中选取"), nil];
    [choiceSheet showInView:self.view];
}

- (void)uploadHead {
    
    UIImage *img = self.ivUserHead.image;
    
    self.checkToken = YES;
    [self getBasicHeader];
    /*
    
    SSFileConfig *uploadConfig = [[SSFileConfig alloc] initWithfileData:UIImageJPEGRepresentation(img,0.3) name:@"attachment" fileName:@"uploadFile.jpg" mimeType:@"image/jpeg"];*/
    NSData *imageData = UIImageJPEGRepresentation(img, 0.3);
    NSString *mimeType = @"image/jpeg";
    
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"data:%@;base64,%@", mimeType,[imageData base64EncodedStringWithOptions:0]],@"file", nil];
    
    self.checkToken = YES;
    
    [SSNetworkRequest postRequest:apiModifyUserHead params:params success:^(id responseObj) {
        //
        NSLog(@"上传结果：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"上传错误：%@",dataObj);
    } headers:self.headers];
}

- (void)uploadImage {
    self.checkToken = YES;
    
    [self getBasicHeader];
    UIImage *img = self.ivUserHead.image;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //接收类型不一致请替换一致text/html或别的
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                         @"text/html",
                                                         @"image/jpeg",
                                                         @"image/png",
                                                         @"application/octet-stream",
                                                         @"text/json",
                                                         nil];
    
    //开始加载头部
    if (self.headers) {
        NSEnumerator *enumerator = [self.headers keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            [manager.requestSerializer setValue:[self.headers objectForKey:key] forHTTPHeaderField:key];
        }
    }
    
//    /////////开始证书认证
//    
//    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"https" ofType:@"cer"];
//    NSData * certData =[NSData dataWithContentsOfFile:cerPath];
//    //    NSSet * certSet = [[NSSet alloc] initWithObjects:certData, nil];
//    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
//    // 是否允许,NO-- 不允许无效的证书
//    [securityPolicy setAllowInvalidCertificates:YES];
//    // 设置证书
//    [securityPolicy setPinnedCertificates:@[certData]];
//    
//    manager.securityPolicy = securityPolicy;
//    /////////结束证书认证
    
    
    [manager POST:apiModifyUserHead parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *imageData =UIImageJPEGRepresentation(img,0.3);
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat =@"yyyyMMddHHmmss";
        NSString *str = [formatter stringFromDate:[NSDate date]];
        NSString *fileName = [NSString stringWithFormat:@"%@.jpg", str];
        
        //上传的参数(上传图片，以文件流的格式)
        [formData appendPartWithFileData:imageData
                                    name:@"file"
                                fileName:fileName
                                mimeType:@"image/jpeg"];
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if ([[responseObject objectForKey:@"status"] intValue]==1) {
            //上传成功
            NSLog(@"上传成功:%@",responseObject);
            
            [self.dicInfo setObject:[[responseObject objectForKey:@"data"] objectForKey:@"UserHead"] forKey:@"UserHead"];
            
            [[NSUserDefaults standardUserDefaults] setObject:self.dicInfo forKey:@"userData"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NeedRefreshInfo" object:nil];
        }else if ([[responseObject objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else if ([[responseObject objectForKey:@"status"] intValue]==1028){
            HUDNormal(INTERNATIONALSTRING(@"缓存失败,请检查图片是否过大"))
        }else{
            HUDNormal(responseObject[@"msg"])
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //上传失败
        NSLog(@"上传失败:%@",[error description]);
    }];
    
//    [manager POST:apiModifyUserHead parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
//        NSData *imageData =UIImageJPEGRepresentation(img,0.3);
//        
//        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//        formatter.dateFormat =@"yyyyMMddHHmmss";
//        NSString *str = [formatter stringFromDate:[NSDate date]];
//        NSString *fileName = [NSString stringWithFormat:@"%@.jpg", str];
//        
//        //上传的参数(上传图片，以文件流的格式)
//        [formData appendPartWithFileData:imageData
//                                    name:@"file"
//                                fileName:fileName
//                                mimeType:@"image/jpeg"];
//    
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
//        //上传成功
//        NSLog(@"上传成功:%@",responseObject);
//        
//        [self.dicInfo setObject:[[responseObject objectForKey:@"data"] objectForKey:@"UserHead"] forKey:@"UserHead"];
//        
//        [[NSUserDefaults standardUserDefaults] setObject:self.dicInfo forKey:@"userData"];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//        
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"NeedRefreshInfo" object:nil];
//        
//        
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        //上传失败
//        NSLog(@"上传失败:%@",[error description]);
//    }];
    /*
    NSURLSessionDataTask *task = [manager POST:apiModifyUserHead parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> _Nonnull formData) {
        
        
        
    } progress:^(NSProgress *_Nonnull uploadProgress) {
        //打印下上传进度
    } success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        //上传成功
    } failure:^(NSURLSessionDataTask *_Nullable task, NSError * _Nonnull error) {
        //上传失败
    }];*/
}

- (NSString *)getYear :(NSString *)timeStemp {
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"yyyyMMddHHMMss"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[timeStemp integerValue]];
    
    [formatter setDateFormat:@"yyyy年"];
    return [formatter stringFromDate:date];
}

- (NSString *)getMonth :(NSString *)timeStemp {
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"yyyyMMddHHMMss"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[timeStemp integerValue]];
    
    [formatter setDateFormat:@"MM月"];
    return [formatter stringFromDate:date];
}

-(void)callSetValue {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    if (storyboard) {
        
        SetValueViewController *setValueViewController = [storyboard instantiateViewControllerWithIdentifier:@"setValueViewController"];
        setValueViewController.name = [self.dicInfo objectForKey:@"NickName"];
        if (setValueViewController) {
            [self.navigationController pushViewController:setValueViewController animated:YES];
        }
    }
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //
    
    if (!self.valueView.hidden) {
        [self.valueView setHidden:YES];
    }
    
    if (indexPath.section==0) {
        [self loadNewHead];
    }else if (indexPath.section==1) {
        
        switch (indexPath.row) {
            case 0:
                [self callSetValue];
                break;
            case 1:
                self.pickerType = 1;
                self.titleLabel.hidden = YES;
                self.titleLabel.text = INTERNATIONALSTRING(@"性别");
                self.arrSource = self.arrSex;
                self.valueView.hidden = NO;
                break;
            case 2:
                self.pickerType = 2;
                self.titleLabel.hidden = NO;
                self.titleLabel.text = INTERNATIONALSTRING(@"出生年月");
                self.arrSource = self.arrAgeYear;
                self.valueView.hidden = NO;
                break;
            case 3:
                self.pickerType = 3;
                self.titleLabel.hidden = NO;
                self.titleLabel.text = INTERNATIONALSTRING(@"身高");
                self.arrSource = self.arrHeight;
                self.valueView.hidden = NO;
                break;
            case 4:
                self.pickerType = 4;
                self.titleLabel.hidden = NO;
                self.titleLabel.text = INTERNATIONALSTRING(@"体重");
                self.arrSource = self.arrWeight;
                self.valueView.hidden = NO;
                break;
            
            default:
                break;
        }
    }else if (indexPath.section==2){
        if (indexPath.row==0) {
    
            self.pickerType = 5;
            self.titleLabel.hidden = NO;
            self.titleLabel.text = INTERNATIONALSTRING(@"运动目标");
            self.arrSource = self.arrTarget;
            self.valueView.hidden = NO;
            
        }
    }
    
    self.tableView.scrollEnabled = self.valueView.hidden;
    
    if (!self.valueView.hidden) {
        [self.pickerView reloadAllComponents];
        
        if (indexPath.section==1) {
            
            switch (indexPath.row) {
                case 1:
                    if([[self.dicInfo objectForKey:@"Sex"] intValue]==0){
                        [self.pickerView selectRow:0 inComponent:0 animated:YES];
                    }else{
                        [self.pickerView selectRow:1 inComponent:0 animated:YES];
                    }
                    break;
                case 2:
                    if ([self.dicInfo objectForKey:@"year"] && [self.dicInfo objectForKey:@"month"]) {
                        [self.pickerView selectRow:[self.arrAgeYear indexOfObject:[NSString stringWithFormat:@"%d年", [[self.dicInfo objectForKey:@"year"] intValue]]] inComponent:0 animated:YES];
                        [self.pickerView selectRow:[self.arrAgeMonth indexOfObject:[NSString stringWithFormat:@"%d月", [[self.dicInfo objectForKey:@"month"] intValue]]] inComponent:1 animated:YES];
                    } else {
                        [self.pickerView selectRow:[self.arrAgeYear indexOfObject:[NSString stringWithFormat:@"%d年", self.yearStr]] inComponent:0 animated:YES];
                        [self.pickerView selectRow:[self.arrAgeMonth indexOfObject:[NSString stringWithFormat:@"%d月", self.monthStr]] inComponent:1 animated:YES];
                    }
                    break;
                case 3:
                    
                    [self.pickerView selectRow:[self.arrHeight indexOfObject:[NSString stringWithFormat:@"%dcm",[[self.dicInfo objectForKey:@"Height"] intValue]]] inComponent:0 animated:YES];
                    break;
                case 4:
                    [self.pickerView selectRow:[self.arrWeight indexOfObject:[NSString stringWithFormat:@"%dkg",[[self.dicInfo objectForKey:@"Weight"] intValue]]] inComponent:0 animated:YES];
                    break;
                    
                default:
                    break;
            }
        }else if (indexPath.section==2){
            if (indexPath.row==0) {
                
                [self.pickerView selectRow:[self.arrTarget indexOfObject:[NSString stringWithFormat:@"%d%@",[[self.dicInfo objectForKey:@"MovingTarget"] intValue], INTERNATIONALSTRING(@"步")]] inComponent:0 animated:YES];
                
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 15;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 79;
            break;
        case 1:
            return 42;
            break;
        default:
            return 42;
            break;
    }
}

#pragma mark - UIPickviewDelegate,UIPickViewDatasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    if (self.pickerType == 2) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (self.pickerType == 2) {
        switch (component) {
            case 1:
                return self.arrAgeMonth.count;
                break;
                
            default:
                return self.arrSource.count;
                break;
        }
    }
        return self.arrSource.count;
    
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (self.pickerType == 2) {
        switch (component) {
            case 0:
                return self.arrSource[row];
                break;
            case 1:
                return self.arrAgeMonth[row];
                break;
            default:
                return self.arrSource[row];
                break;
        }
    } else {
        return [self.arrSource objectAtIndex:row];
    }
    
}
/*
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel* pickerLabel = (UILabel*)view;
    if (!pickerLabel){
        pickerLabel = [[UILabel alloc] init];
        // Setup label properties - frame, font, colors etc
        //adjustsFontSizeToFitWidth property to YES
        pickerLabel.adjustsFontSizeToFitWidth = YES;
        [pickerLabel setTextAlignment:NSTextAlignmentLeft];
        [pickerLabel setBackgroundColor:[UIColor clearColor]];
        [pickerLabel setFont:[UIFont boldSystemFontOfSize:15]];
    }
    // Fill the label text here
    pickerLabel.text=[self pickerView:pickerView titleForRow:row forComponent:component];
    return pickerLabel;
}*/

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // 拍照
        if ([self isCameraAvailable] && [self doesCameraSupportTakingPhotos]) {
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
            if ([self isFrontCameraAvailable]) {
                controller.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            }
            NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
            [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
            controller.mediaTypes = mediaTypes;
            controller.delegate = self;
            [self presentViewController:controller
                               animated:YES
                             completion:^(void){
                                 NSLog(@"Picker View Controller is presented");
                             }];
        }
        
    } else if (buttonIndex == 1) {
        // 从相册中选取
        if ([self isPhotoLibraryAvailable]) {
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
            [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
            controller.mediaTypes = mediaTypes;
            controller.delegate = self;
            [self presentViewController:controller
                               animated:YES
                             completion:^(void){
                                 NSLog(@"Picker View Controller is presented");
                             }];
        }
    }
}

#pragma mark camera utility
- (BOOL) isCameraAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL) isRearCameraAvailable{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (BOOL) isFrontCameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

- (BOOL) doesCameraSupportTakingPhotos {
    return [self cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL) isPhotoLibraryAvailable{
    return [UIImagePickerController isSourceTypeAvailable:
            UIImagePickerControllerSourceTypePhotoLibrary];
}
- (BOOL) canUserPickVideosFromPhotoLibrary{
    return [self
            cameraSupportsMedia:(__bridge NSString *)kUTTypeMovie sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}
- (BOOL) canUserPickPhotosFromPhotoLibrary{
    return [self
            cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL) cameraSupportsMedia:(NSString *)paramMediaType sourceType:(UIImagePickerControllerSourceType)paramSourceType{
    __block BOOL result = NO;
    if ([paramMediaType length] == 0) {
        return NO;
    }
    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    [availableMediaTypes enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *mediaType = (NSString *)obj;
        if ([mediaType isEqualToString:paramMediaType]){
            result = YES;
            *stop= YES;
        }
    }];
    return result;
}

#pragma mark VPImageCropperDelegate
- (void)imageCropper:(VPImageCropperViewController *)cropperViewController didFinished:(UIImage *)editedImage {
    self.ivUserHead.image = editedImage;
    
//    [self uploadHead];
    [self uploadImage];
    
    [cropperViewController dismissViewControllerAnimated:YES completion:^{
        // TO DO
    }];
}

- (void)imageCropperDidCancel:(VPImageCropperViewController *)cropperViewController {
    [cropperViewController dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark - UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^() {
        UIImage *portraitImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        //        portraitImg = [self imageByScalingToMaxSize:portraitImg];
        portraitImg = [UIImage imageWithData:UIImageJPEGRepresentation(portraitImg,0.3)]; //修改这里
        // present the cropper view controller
        VPImageCropperViewController *imgCropperVC = [[VPImageCropperViewController alloc] initWithImage:portraitImg cropFrame:CGRectMake(0, 100.0f, self.view.frame.size.width, self.view.frame.size.width) limitScaleRatio:3.0];
        imgCropperVC.delegate = self;
        [self presentViewController:imgCropperVC animated:YES completion:^{
            // TO DO
        }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^(){
    }];
}

@end
