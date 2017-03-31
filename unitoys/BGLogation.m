//
//  BGLogation.m
//  locationdemo
//
//  Created by yebaojia on 16/2/24.
//  Copyright © 2016年 mjia. All rights reserved.
//

#import "BGLogation.h"
#import "BGTask.h"
#import "global.h"
@interface BGLogation()
{
    BOOL isCollect;
}
@property (strong , nonatomic) BGTask *bgTask; //后台任务
@property (strong , nonatomic) NSTimer *restarTimer; //重新开启后台任务定时器
@property (strong , nonatomic) NSTimer *closeCollectLocationTimer; //关闭定位定时器 （减少耗电）
@property (nonatomic, assign) BOOL isShowNetwork;//是否显示网络请求提示
@property (nonatomic, assign) BOOL isShowlocation;//是否显示定位权限提示
@end
@implementation BGLogation
//初始化
-(instancetype)init
{
    if(self = [super init])
    {
        //
        _bgTask = [BGTask shareBGTask];
        isCollect = NO;
        //监听进入后台通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}
+(CLLocationManager *)shareBGLocation
{
    static CLLocationManager *_locationManager;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
            _locationManager.allowsBackgroundLocationUpdates = YES;
        }
            _locationManager.pausesLocationUpdatesAutomatically = NO;
    });
    return _locationManager;
}
//后台监听方法
-(void)applicationEnterBackground
{
    NSLog(@"come in background");
    CLLocationManager *locationManager = [BGLogation shareBGLocation];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone; // 不移动也可以后台刷新回调
    if ([[UIDevice currentDevice].systemVersion floatValue]>= 8.0) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
    [_bgTask beginNewBackgroundTask];
}
//重启定位服务
-(void)restartLocation
{
    NSLog(@"重新启动定位");
    CLLocationManager *locationManager = [BGLogation shareBGLocation];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone; // 不移动也可以后台刷新回调
    if ([[UIDevice currentDevice].systemVersion floatValue]>= 8.0) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
    [self.bgTask beginNewBackgroundTask];
}
//开启服务
- (void)startLocation {
    NSLog(@"开启定位");
    
    if ([CLLocationManager locationServicesEnabled] == NO) {
        NSLog(@"locationServicesEnabled false");
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
    } else {
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
            NSLog(@"authorizationStatus failed");
        } else {
            NSLog(@"authorizationStatus authorized");
            CLLocationManager *locationManager = [BGLogation shareBGLocation];
            locationManager.distanceFilter = kCLDistanceFilterNone;
            
            if([[UIDevice currentDevice].systemVersion floatValue]>= 8.0) {
                [locationManager requestAlwaysAuthorization];
            }
            [locationManager startUpdatingLocation];
        }
    }
}

//停止后台定位
-(void)stopLocation
{
    NSLog(@"停止定位");
    isCollect = NO;
    CLLocationManager *locationManager = [BGLogation shareBGLocation];
    [locationManager stopUpdatingLocation];
}
#pragma mark --delegate
//定位回调里执行重启定位和关闭定位
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
    {
        // 设备的当前位置
        CLLocation *currLocation = [locations lastObject];
        NSString *latitude = [NSString stringWithFormat:@"%3.5f",currLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%3.5f",currLocation.coordinate.longitude];
        NSString *altitude = [NSString stringWithFormat:@"%3.5f",currLocation.altitude];
        NSString *speed = [NSString stringWithFormat:@"%3.5f", currLocation.speed];
        NSString *timeS = [NSString stringWithFormat:@"%@", currLocation.timestamp];
        NSString *currentDayTime = [timeS substringToIndex:10];
        NSLog(@"截取到的当前时间 -- %@",currentDayTime);
        NSLog(@"定位收集: -- %@", locations);
        NSLog(@"定位收集:纬度:%@,经度:%@,高度:%@,速度:%@,时间:%@",latitude,longitude,altitude,speed,timeS);
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];  //保存定位信息
        NSData *locationListArrData = [userDefaults objectForKey:@"locationList"];
        NSMutableArray *locationListArr = [NSMutableArray array];
        if (locationListArrData) {
            locationListArr = [NSKeyedUnarchiver unarchiveObjectWithData:locationListArrData];
//            NSLog(@"存储在本地的定位信息 -- %@", locationListArr);
        }
        if (locationListArr.count) {
            //有存储数据
            CLLocation *firstLocation = locationListArr[0];
            NSString *timeStr = [NSString stringWithFormat:@"%@", firstLocation.timestamp];
            NSString *dayTime = [timeStr substringToIndex:10];
            NSLog(@"截取到的存储时间 -- %@",dayTime);
            if (![dayTime isEqualToString:currentDayTime]) {
                //不是同一天
                [locationListArr removeAllObjects];
                [locationListArr addObject:currLocation];
            } else {
                //是同一天
                CLLocation *beforLocation = locationListArr.lastObject;
                NSString *latitudeStr = [NSString stringWithFormat:@"%3.5f",beforLocation.coordinate.latitude];
                NSString *longitudeStr = [NSString stringWithFormat:@"%3.5f",beforLocation.coordinate.longitude];
                CLLocationCoordinate2D startCoordinate = CLLocationCoordinate2DMake([latitudeStr doubleValue], [longitudeStr doubleValue]);
                //当前确定到的位置数据
                CLLocationCoordinate2D endCoordinate;
                endCoordinate.latitude = currLocation.coordinate.latitude;
                endCoordinate.longitude = currLocation.coordinate.longitude;
                //移动距离的计算
                double meters = [self calculateDistanceWithStart:startCoordinate end:endCoordinate];
                NSLog(@"计算的位移为%f米",meters);
                if (meters >= 5){
                    NSLog(@"添加进位置数组");
                    [locationListArr addObject:currLocation];
                }else{
                    NSLog(@"不添加进位置数组");
                }
            }
        } else {
            //没有存储数据
            [locationListArr addObject:currLocation];
        }
        NSData *listData = [NSKeyedArchiver archivedDataWithRootObject:locationListArr];
        [userDefaults setObject:listData forKey:@"locationList"];
        [userDefaults synchronize];
        
        //如果正在10秒定时收集的时间，不需要执行延时开启和关闭定位
        if (isCollect) {
            return;
        }
        [self performSelector:@selector(restartLocation) withObject:nil afterDelay:120];
        [self performSelector:@selector(stopLocation) withObject:nil afterDelay:10];
        isCollect = YES;//标记正在定位
    }
- (void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error
{
    // NSLog(@"locationManager error:%@",error);
    
    switch([error code])
    {
        case kCLErrorNetwork: // general, network-related error
        {
            if (!self.isShowNetwork) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"网络错误") message:INTERNATIONALSTRING(@"请检查网络连接") delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                self.isShowNetwork = YES;
            }
        }
            break;
        case kCLErrorDenied:{
            if (!self.isShowlocation) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:INTERNATIONALSTRING(@"请开启后台服务") message:INTERNATIONALSTRING(@"应用没有开启后台定位功能，需要在在设置->通用->后台应用刷新开启") delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                self.isShowlocation = YES;
            }
        }
            break;
        default:
        {
            
        }
            break;
    }
}
    
#pragma mark - 距离测算
- (double)calculateDistanceWithStart:(CLLocationCoordinate2D)start end:(CLLocationCoordinate2D)end {
    
    double meter = 0;
    
    double startLongitude = start.longitude;
    double startLatitude = start.latitude;
    double endLongitude = end.longitude;
    double endLatitude = end.latitude;
    
    double radLatitude1 = startLatitude * M_PI / 180.0;
    double radLatitude2 = endLatitude * M_PI / 180.0;
    double a = fabs(radLatitude1 - radLatitude2);
    double b = fabs(startLongitude * M_PI / 180.0 - endLongitude * M_PI / 180.0);
    
    double s = 22 * asin(sqrt(pow(sin(a/2),2) + cos(radLatitude1) * cos(radLatitude2) * pow(sin(b/2),2)));
    s = s * 6378137;
    
    meter = round(s * 10000) / 10000;
    return meter;
}

@end
