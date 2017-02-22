//
//  HomeViewController.h
//  unitoys
//
//  Created by sumars on 16/9/20.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"
#import "SDCycleScrollView.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BlueToothDataManager.h"

@interface HomeViewController : BaseTableController<UICollectionViewDelegate,UICollectionViewDataSource,SDCycleScrollViewDelegate,CBCentralManagerDelegate, CBPeripheralDelegate>


@property (nonatomic,strong) NSMutableArray *arrPicUrls;
@property (nonatomic,strong) NSMutableArray *arrPicJump;
@property (nonatomic, strong) NSMutableArray *arrPicTitles;

@property (strong,nonatomic) NSMutableArray *arrCountry;

@property (weak, nonatomic) IBOutlet UILabel *lblStepNum;
@property (weak, nonatomic) IBOutlet UILabel *lblKM;
@property (weak, nonatomic) IBOutlet UILabel *lblDate;
@property (weak, nonatomic) IBOutlet UILabel *lblKcal;

@property (weak, nonatomic) IBOutlet UIView *ivTutorial;

@property (weak, nonatomic) IBOutlet UIView *ivQuickSetting;
@property (weak, nonatomic) IBOutlet UIView *ivDevices;

@property (weak, nonatomic) IBOutlet SDCycleScrollView *AdView;
@property (weak, nonatomic) IBOutlet UICollectionView *hotCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *lblOrderHint;

@property (weak, nonatomic) IBOutlet UIImageView *ivLogoPic1;
@property (weak, nonatomic) IBOutlet UILabel *lblFlow1;
@property (weak, nonatomic) IBOutlet UILabel *lblTotalPrice1;
@property (weak, nonatomic) IBOutlet UILabel *lblExpireDays1;

@property (weak, nonatomic) IBOutlet UIButton *btnOrderStatus1;

@property (weak, nonatomic) IBOutlet UIImageView *ivLogoPic2;
@property (weak, nonatomic) IBOutlet UILabel *lblFlow2;
@property (weak, nonatomic) IBOutlet UILabel *lblTotalPrice2;
@property (weak, nonatomic) IBOutlet UILabel *lblExpireDays2;

@property (weak, nonatomic) IBOutlet UIButton *btnOrderStatus2;

@property (weak, nonatomic) IBOutlet UIImageView *ivLogoPic3;
@property (weak, nonatomic) IBOutlet UILabel *lblFlow3;
@property (weak, nonatomic) IBOutlet UILabel *lblTotalPrice3;
@property (weak, nonatomic) IBOutlet UILabel *lblExpireDays3;

@property (weak, nonatomic) IBOutlet UIButton *btnOrderStatus3;
@property (weak, nonatomic) IBOutlet UIView *orderFoot1;
@property (weak, nonatomic) IBOutlet UIView *orderFoot2;

@property (readwrite) NSArray *arrOrderList;
@property (nonatomic, strong) UIButton *leftButton;

@property (nonatomic, copy) NSString *simtype;

/*通讯录*/
@property (nonatomic,strong) NSArray *contactsDataArr;//数据源

/*蓝牙相关*/
@property (nonatomic, strong) CBCentralManager *mgr;
@property (nonatomic, strong) NSMutableArray *peripherals;
//外设
@property (nonatomic, strong) CBPeripheral *peripheral;
//信号最强的外设
@property (nonatomic, strong) CBPeripheral *strongestRssiPeripheral;
//写属性特征
@property (nonatomic, strong) CBCharacteristic *characteristic;
//通知属性特征
@property (nonatomic, strong) CBCharacteristic *notifyCharacteristic;
@property (nonatomic, strong) CBCharacteristic *notifyCharacteristic2;
@property (nonatomic, strong) CBCharacteristic *notifyCharacteristic3;
//存储uuid的数组
@property (nonatomic, strong) NSMutableArray *uuidArray;
//当天计步数组
@property (nonatomic, strong) NSMutableArray *todays;
//昨天计步数组
@property (nonatomic, strong) NSMutableArray *yesterdays;
//前天计步数组
@property (nonatomic, strong) NSMutableArray *berforeYesterdays;
//三天以前的计步数据数组
@property (nonatomic, strong) NSMutableArray *threeDaysAgo;
//存放mac地址的字典
@property (nonatomic, strong) NSMutableDictionary *macAddressDict;
//存放RSSI的字典
@property (nonatomic, strong) NSMutableDictionary *RSSIDict;

//存放数据包的数组
@property (nonatomic, strong) NSMutableArray *dataPacketArray;

//存放最终总数据的字符串
@property (nonatomic, copy) NSString *totalString;

//存放绑定的设备的信息
@property (nonatomic, strong) NSDictionary *boundedDeviceInfo;

//记录需要激活的大王卡的序列号(空卡序列号)
@property (nonatomic, copy) NSString *bigKingCardNumber;

//激活的订单id
@property (nonatomic, copy) NSString *activityOrderId;

//计时器相关
@property (nonatomic, strong)NSTimer *timer;
@property (nonatomic, assign)int time;

//记录接收到包的类型
@property (nonatomic, assign) int dataPackegType;

@property (weak, nonatomic) IBOutlet UIView *sportView;

- (IBAction)viewAllOrders:(id)sender;

- (IBAction)viewAllContury:(id)sender;


@end
