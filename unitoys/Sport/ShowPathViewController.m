//
//  ShowPathViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/3/4.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ShowPathViewController.h"
#import <MapKit/MapKit.h>

@interface ShowPathViewController ()<MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
//存放用户位置的数组
@property (nonatomic, strong) NSMutableArray *locationMutableArray;

@end

@implementation ShowPathViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = INTERNATIONALSTRING(@"轨迹");
    
    //用户位置追踪
    _mapView.userTrackingMode = MKUserTrackingModeFollow;
    /**
     地图的样式:
     MKMapTypeStandard, 标准地图
     MKMapTypeSatellite, 卫星地图
     MKMapTypeHybrid, 混合地图
     MKMapTypeSatelliteFlyover, 卫星立体地图
     MKMapTypeHybridFlyover, 混合立体地图
     */
    _mapView.mapType = MKMapTypeStandard;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];  //保存定位信息
    NSData *locationListArrData = [userDefaults objectForKey:@"locationList"];
    _locationMutableArray = [NSMutableArray array];
    if (locationListArrData) {
        _locationMutableArray = [NSKeyedUnarchiver unarchiveObjectWithData:locationListArrData];
        NSLog(@"存储在本地的定位信息 -- %@", _locationMutableArray);
    }
    [self showPath];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)showPath {
    if (_locationMutableArray.count >= 2) {
        for (int i = 1; i < _locationMutableArray.count; i++) {
            CLLocation *beforLocation = _locationMutableArray[i-1];
            NSString *latitudeStr = [NSString stringWithFormat:@"%3.5f",beforLocation.coordinate.latitude];
            NSString *longitudeStr = [NSString stringWithFormat:@"%3.5f",beforLocation.coordinate.longitude];
            CLLocationCoordinate2D startCoordinate = CLLocationCoordinate2DMake([latitudeStr doubleValue], [longitudeStr doubleValue]);
            
            //当前确定到的位置数据
            CLLocation *afterLocation = _locationMutableArray[i];
            CLLocationCoordinate2D endCoordinate;
            endCoordinate.latitude = afterLocation.coordinate.latitude;
            endCoordinate.longitude = afterLocation.coordinate.longitude;
            //开始绘制轨迹
            CLLocationCoordinate2D pointsToUse[2];
            pointsToUse[0] = startCoordinate;
            pointsToUse[1] = endCoordinate;
            //调用 addOverlay 方法后,会进入 rendererForOverlay 方法,完成轨迹的绘制
            MKPolyline *lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:2];
            [_mapView addOverlay:lineOne];
        }
    }
}

#pragma mark - MKMapViewDelegate
/**
 更新用户位置，只要用户改变则调用此方法（包括第一次定位到用户位置）
 第一种画轨迹的方法:我们使用在地图上的变化来描绘轨迹,这种方式不用考虑从 CLLocationManager 取出的经纬度在 mapView 上显示有偏差的问题
 */
-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    NSString *latitude = [NSString stringWithFormat:@"%3.5f",userLocation.coordinate.latitude];
    NSString *longitude = [NSString stringWithFormat:@"%3.5f",userLocation.coordinate.longitude];
    NSLog(@"更新的用户位置:纬度:%@, 经度:%@",latitude,longitude);
    
    //设置地图显示范围(如果不进行区域设置会自动显示区域范围并指定当前用户位置为地图中心点)
    MKCoordinateSpan span = MKCoordinateSpanMake(0.05, 0.05);
    MKCoordinateRegion region=MKCoordinateRegionMake(userLocation.location.coordinate, span);
    [_mapView setRegion:region animated:true];
    
    if (_locationMutableArray.count != 0) {
        
        //从位置数组中取出最新的位置数据
        CLLocation *currLocation = _locationMutableArray.lastObject;
        NSString *latitudeStr = [NSString stringWithFormat:@"%3.5f",currLocation.coordinate.latitude];
        NSString *longitudeStr = [NSString stringWithFormat:@"%3.5f",currLocation.coordinate.longitude];
        CLLocationCoordinate2D startCoordinate = CLLocationCoordinate2DMake([latitudeStr doubleValue], [longitudeStr doubleValue]);
        
        //当前确定到的位置数据
        CLLocationCoordinate2D endCoordinate;
        endCoordinate.latitude = userLocation.coordinate.latitude;
        endCoordinate.longitude = userLocation.coordinate.longitude;
        
        //移动距离的计算
        double meters = [self calculateDistanceWithStart:startCoordinate end:endCoordinate];
        NSLog(@"移动的距离为%f米",meters);
        
        //为了美化移动的轨迹,移动的位置超过10米,方可添加进位置的数组
        if (meters >= 5){
            
            NSLog(@"添加进位置数组");
//            NSString *locationString = [NSString stringWithFormat:@"%f,%f",userLocation.coordinate.latitude, userLocation.coordinate.longitude];
            [_locationMutableArray addObject:userLocation];
            
            //开始绘制轨迹
            CLLocationCoordinate2D pointsToUse[2];
            pointsToUse[0] = startCoordinate;
            pointsToUse[1] = endCoordinate;
            //调用 addOverlay 方法后,会进入 rendererForOverlay 方法,完成轨迹的绘制
            MKPolyline *lineOne = [MKPolyline polylineWithCoordinates:pointsToUse count:2];
            [_mapView addOverlay:lineOne];
//            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//            NSData *listData = [NSKeyedArchiver archivedDataWithRootObject:_locationMutableArray];
//            [userDefaults setObject:listData forKey:@"locationList"];
//            [userDefaults synchronize];
            
        }else{
            
            NSLog(@"不添加进位置数组");
        }
    }else{
        
        //存放位置的数组,如果数组包含的对象个数为0,那么说明是第一次进入,将当前的位置添加到位置数组
//        NSString *locationString = [NSString stringWithFormat:@"%f,%f",userLocation.coordinate.latitude, userLocation.coordinate.longitude];
        [_locationMutableArray addObject:userLocation];
//        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//        NSData *listData = [NSKeyedArchiver archivedDataWithRootObject:_locationMutableArray];
//        [userDefaults setObject:listData forKey:@"locationList"];
//        [userDefaults synchronize];
    }
}


-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    
    if ([overlay isKindOfClass:[MKPolyline class]]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        MKPolylineView *polyLineView = [[MKPolylineView alloc] initWithPolyline:overlay];
        polyLineView.lineWidth = 10; //折线宽度
        polyLineView.strokeColor = [UIColor blueColor]; //折线颜色
        return (MKOverlayRenderer *)polyLineView;
#pragma clang diagnostic pop
    }
    return nil;
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
