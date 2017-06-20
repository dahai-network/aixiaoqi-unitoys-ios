//
//  PurviewSettingViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/3/25.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "PurviewSettingViewController.h"
#import "PurviewSettingTableViewCell.h"
#import <CoreLocation/CoreLocation.h>
#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCellularData.h>


#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface PurviewSettingViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (strong, nonatomic) IBOutlet UIView *headView;

@end

@implementation PurviewSettingViewController

- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        self.dataArr = [NSMutableArray array];
    }
    return _dataArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableDictionary *dict1 = [NSMutableDictionary dictionaryWithDictionary:@{@"lblName":@"定位权限", @"status":@"未知", @"img":@"positioning"}];
    NSMutableDictionary *dict2 = [NSMutableDictionary dictionaryWithDictionary:@{@"lblName":@"通讯录权限", @"status":@"未知", @"img":@"contacts"}];
    NSMutableDictionary *dict3 = [NSMutableDictionary dictionaryWithDictionary:@{@"lblName":@"相册权限", @"status":@"未知", @"img":@"photos"}];
    NSMutableDictionary *dict4 = [NSMutableDictionary dictionaryWithDictionary:@{@"lblName":@"麦克风权限", @"status":@"未知", @"img":@"mike"}];
    NSMutableDictionary *dict5 = [NSMutableDictionary dictionaryWithDictionary:@{@"lblName":@"相机权限", @"status":@"未知", @"img":@"camera"}];
    NSMutableDictionary *dict6 = [NSMutableDictionary dictionaryWithDictionary:@{@"lblName":@"通知权限", @"status":@"未知", @"img":@"notice"}];
    NSMutableDictionary *dict7 = [NSMutableDictionary dictionaryWithDictionary:@{@"lblName":@"后台应用刷新权限", @"status":@"未知", @"img":@"site"}];
    NSMutableDictionary *dict8 = [NSMutableDictionary dictionaryWithDictionary:@{@"lblName":@"无线数据权限", @"status":@"未知", @"img":@"data"}];
    self.dataArr = [NSMutableArray arrayWithObjects:dict1, dict2, dict3, dict4, dict5, dict6, dict7, dict8, nil];
    self.title = INTERNATIONALSTRING(@"权限设置");
    self.tableView.tableFooterView = [UIView new];
    self.tableView.tableHeaderView = self.headView;
    
    //定位权限
    [self checkLocationPurving];
    
    //通讯录权限
    if (SYSTEM_VERSION_LESS_THAN(@"9")) {
        [self checkAddressBookPurvingBeforeIOS9];
    }else {
        [self checkAddressBookPurvingOnIOS9AndLater];
    }
    
    //相册权限
    [self checkPhotoPurving];
    
    //麦克风权限
    [self checkMicrophonePurving];
    
    //相机权限
    [self checkCameraPurving];
    
    //通知权限
    [self checkNotificationPurving];
    
    //后台应用刷新权限
    [self checkRefreshBackgroundPurving];
    
    //无线数据权限（联网权限）
    [self checkNetWorkPurving];
    [self.tableView reloadData];
    
    // Do any additional setup after loading the view from its nib.
}

#pragma mark 定位权限
- (void)checkLocationPurving {
    BOOL isLocation = [CLLocationManager locationServicesEnabled];
    if (!isLocation) {
        NSLog(@"定位权限 --> not turn on the location");
    }
    CLAuthorizationStatus CLstatus = [CLLocationManager authorizationStatus];
    switch (CLstatus) {
        case kCLAuthorizationStatusAuthorizedAlways:
            NSLog(@"定位权限 --> 始终开启 Always Authorized");
            [self.dataArr[0] setObject:@"始终开启" forKey:@"status"];
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            NSLog(@"定位权限 --> 使用时开启 AuthorizedWhenInUse");
            [self.dataArr[0] setObject:@"使用时开启" forKey:@"status"];
            break;
        case kCLAuthorizationStatusDenied:
            NSLog(@"定位权限 --> 关闭 Denied");
            [self.dataArr[0] setObject:@"关闭" forKey:@"status"];
            break;
        case kCLAuthorizationStatusNotDetermined:
            NSLog(@"定位权限 --> 未授权 not Determined");
            [self.dataArr[0] setObject:@"未授权" forKey:@"status"];
            break;
        case kCLAuthorizationStatusRestricted:
            NSLog(@"定位权限 --> 无权限 Restricted");
            [self.dataArr[0] setObject:@"无权限" forKey:@"status"];
            break;
        default:
            break;
    }
    
}

#pragma mark iOS 9之前通讯录权限
- (void)checkAddressBookPurvingBeforeIOS9 {
    ABAuthorizationStatus ABstatus = ABAddressBookGetAuthorizationStatus();
    switch (ABstatus) {
        case kABAuthorizationStatusAuthorized:
            NSLog(@"iOS9之前通讯录权限 --> 开启 Authorized");
            [self.dataArr[1] setObject:@"开启" forKey:@"status"];
            break;
        case kABAuthorizationStatusDenied:
            NSLog(@"iOS9之前通讯录权限 --> 关闭 Denied");
            [self.dataArr[1] setObject:@"关闭" forKey:@"status"];
            break;
        case kABAuthorizationStatusNotDetermined:
            NSLog(@"iOS9之前通讯录权限 --> 未授权 not Determined");
            [self.dataArr[1] setObject:@"未授权" forKey:@"status"];
            break;
        case kABAuthorizationStatusRestricted:
            NSLog(@"iOS9之前通讯录权限 --> 无权限 Restricted");
            [self.dataArr[1] setObject:@"无权限" forKey:@"status"];
            break;
        default:
            break;
    }
}

#pragma mark iOS 9之后通讯录权限
- (void)checkAddressBookPurvingOnIOS9AndLater {
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    switch (status) {
        case CNAuthorizationStatusAuthorized: {
            NSLog(@"iOS9之后通讯录权限 --> 开启 Authorized:");
            [self.dataArr[1] setObject:@"开启" forKey:@"status"];
        }
            break;
        case CNAuthorizationStatusDenied:{
            NSLog(@"iOS9之后通讯录权限 --> 关闭 Denied");
            [self.dataArr[1] setObject:@"关闭" forKey:@"status"];
        }
            break;
        case CNAuthorizationStatusRestricted:{
            NSLog(@"iOS9之后通讯录权限 --> 无权限 Restricted");
            [self.dataArr[1] setObject:@"无权限" forKey:@"status"];
        }
            break;
        case CNAuthorizationStatusNotDetermined:{
            NSLog(@"iOS9之后通讯录权限 --> 未授权 NotDetermined");
            [self.dataArr[1] setObject:@"未授权" forKey:@"status"];
        }
        break;
    }
}

#pragma mark 相册权限
- (void)checkPhotoPurving {
    PHAuthorizationStatus photoAuthorStatus = [PHPhotoLibrary authorizationStatus];
    switch (photoAuthorStatus) {
        case PHAuthorizationStatusAuthorized:
            NSLog(@"相册权限 --> 开启 Authorized");
            [self.dataArr[2] setObject:@"开启" forKey:@"status"];
            break;
        case PHAuthorizationStatusDenied:
            NSLog(@"相册权限 --> 关闭 Denied");
            [self.dataArr[2] setObject:@"关闭" forKey:@"status"];
            break;
        case PHAuthorizationStatusNotDetermined:
            NSLog(@"相册权限 --> 未授权 not Determined");
            [self.dataArr[2] setObject:@"未授权" forKey:@"status"];
            break;
        case PHAuthorizationStatusRestricted:
            NSLog(@"相册权限 --> 无权限 Restricted");
            [self.dataArr[2] setObject:@"无权限" forKey:@"status"];
            break;
        default:
            break;
    }
}

#pragma mark 麦克风权限
- (void)checkMicrophonePurving {
    AVAuthorizationStatus AVMicrophonestatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];//麦克风权限
    switch (AVMicrophonestatus) {
            //允许状态
        case AVAuthorizationStatusAuthorized:
            NSLog(@"麦克风权限 --> 开启 Authorized");
            [self.dataArr[3] setObject:@"开启" forKey:@"status"];
            break;
            //不允许状态，可以弹出一个alertview提示用户在隐私设置中开启权限
        case AVAuthorizationStatusDenied:
            NSLog(@"麦克风权限 --> 关闭 Denied");
            [self.dataArr[3] setObject:@"关闭" forKey:@"status"];
            break;
            //未知，第一次申请权限
        case AVAuthorizationStatusNotDetermined:
            NSLog(@"麦克风权限 --> 未授权 not Determined");
            [self.dataArr[3] setObject:@"未授权" forKey:@"status"];
            break;
            //此应用程序没有被授权访问,可能是家长控制权限
        case AVAuthorizationStatusRestricted:
            NSLog(@"麦克风权限 --> 无权限 Restricted");
            [self.dataArr[3] setObject:@"无权限" forKey:@"status"];
            break;
        default:
            break;
    }
}

#pragma mark 相机权限
- (void)checkCameraPurving {
    AVAuthorizationStatus AVCamerastatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];//相机权限
    switch (AVCamerastatus) {
            //允许状态
        case AVAuthorizationStatusAuthorized:
            NSLog(@"相机权限 --> 开启 Authorized");
            [self.dataArr[4] setObject:@"开启" forKey:@"status"];
            break;
            //不允许状态，可以弹出一个alertview提示用户在隐私设置中开启权限
        case AVAuthorizationStatusDenied:
            NSLog(@"相机权限 --> 关闭 Denied");
            [self.dataArr[4] setObject:@"关闭" forKey:@"status"];
            break;
            //未知，第一次申请权限
        case AVAuthorizationStatusNotDetermined:
            NSLog(@"相机权限 --> 未授权 not Determined");
            [self.dataArr[4] setObject:@"未授权" forKey:@"status"];
            break;
            //此应用程序没有被授权访问,可能是家长控制权限
        case AVAuthorizationStatusRestricted:
            NSLog(@"相机权限 --> 无权限 Restricted");
            [self.dataArr[4] setObject:@"无权限" forKey:@"status"];
            break;
        default:
            break;
    }
}

#pragma mark 通知权限
- (void)checkNotificationPurving {
    UIUserNotificationType notifiType = [[UIApplication sharedApplication] currentUserNotificationSettings].types;
    switch (notifiType) {
        case UIUserNotificationTypeNone:
            NSLog(@"通知权限 --> UIUserNotificationTypeNone");
            [self.dataArr[5] setObject:@"关闭" forKey:@"status"];
            break;
        case UIUserNotificationTypeBadge:
            NSLog(@"通知权限 --> UIUserNotificationTypeBadge");
            [self.dataArr[5] setObject:@"应用图标标记" forKey:@"status"];
            break;
        case UIUserNotificationTypeSound:
            NSLog(@"通知权限 --> UIUserNotificationTypeSound");
            [self.dataArr[5] setObject:@"声音" forKey:@"status"];
            break;
        case UIUserNotificationTypeAlert:
            NSLog(@"通知权限 --> UIUserNotificationTypeAlert");
            [self.dataArr[5] setObject:@"通知中心显示" forKey:@"status"];
            break;
        default:
            NSLog(@"通知权限 --> 这是什么鬼类型 %lu", (unsigned long)notifiType);
            [self.dataArr[5] setObject:@"允许通知" forKey:@"status"];
            break;
    }
}

#pragma mark 后台应用刷新权限
- (void)checkRefreshBackgroundPurving {
    if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusDenied) {
        NSLog(@"后台应用刷新权限 --> 关闭 UIBackgroundRefreshStatusDenied");
        [self.dataArr[6] setObject:@"关闭" forKey:@"status"];
    } else if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusRestricted) {
        NSLog(@"后台应用刷新权限 --> 无权限 UIBackgroundRefreshStatusRestricted");
        [self.dataArr[6] setObject:@"无权限" forKey:@"status"];
    } else if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusAvailable) {
        NSLog(@"后台应用刷新权限 --> 开启 UIBackgroundRefreshStatusAvailable");
        [self.dataArr[6] setObject:@"开启" forKey:@"status"];
    } else {
        NSLog(@"后台应用刷新权限 --> 未知类型");
    }
}

#pragma mark 无线数据权限（联网权限）
- (void)checkNetWorkPurving {
    CTCellularData *cellularData = [[CTCellularData alloc]init];
    cellularData.cellularDataRestrictionDidUpdateNotifier = ^(CTCellularDataRestrictedState state)
    { //获取联网状态
        switch (state)
        {
        case kCTCellularDataRestricted:
                NSLog(@"无线数据权限 --> 关闭 Restricrted");
                [self.dataArr[7] setObject:@"关闭" forKey:@"status"];
                break;
        case kCTCellularDataNotRestricted:
                NSLog(@"无线数据权限 --> 开启 Not Restricted");
                [self.dataArr[7] setObject:@"开启" forKey:@"status"];
                break;
            //未知，第一次请求
        case kCTCellularDataRestrictedStateUnknown:
                NSLog(@"无线数据权限 --> 未授权 Unknown");
                [self.dataArr[7] setObject:@"未授权" forKey:@"status"];
                break;
        default:
                break;
        };
    };
}

#pragma mark - tableView代理方法
#pragma mark 返回行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

#pragma mark 返回行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55;
}

#pragma mark 返回cell内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier=@"PurviewSettingTableViewCell";
    PurviewSettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell=[[[NSBundle mainBundle] loadNibNamed:@"PurviewSettingTableViewCell" owner:nil options:nil] firstObject];
    }
    NSDictionary *dict = self.dataArr[indexPath.row];
    cell.lblName.text = dict[@"lblName"];
    cell.lblLast.text = dict[@"status"];
    cell.imgSettingImage.image = [UIImage imageNamed:dict[@"img"]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
        //打开app设置界面
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    } else {
        NSLog(@"打不开");
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

@end
