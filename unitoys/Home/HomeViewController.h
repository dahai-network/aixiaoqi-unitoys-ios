//
//  HomeViewController.h
//  unitoys
//
//  Created by sumars on 16/9/20.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseTableController.h"
#import "SDCycleScrollView.h"
//#import <CoreBluetooth/CoreBluetooth.h>
#import "BlueToothDataManager.h"

@interface HomeViewController : BaseTableController<UICollectionViewDelegate,UICollectionViewDataSource,SDCycleScrollViewDelegate>


@property (nonatomic,strong) NSMutableArray *arrPicUrls;
@property (nonatomic,strong) NSMutableArray *arrPicJump;
@property (nonatomic, strong) NSMutableArray *arrPicTitles;

@property (strong,nonatomic) NSMutableArray *arrCountry;

@property (weak, nonatomic) IBOutlet UIView *ivTutorial;

@property (weak, nonatomic) IBOutlet UIView *ivQuickSetting;
@property (weak, nonatomic) IBOutlet UIView *ivDevices;

@property (weak, nonatomic) IBOutlet SDCycleScrollView *AdView;
@property (weak, nonatomic) IBOutlet UICollectionView *hotCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *lblOrderHint;

@property (weak, nonatomic) IBOutlet UIImageView *ivLogoPic1;
@property (weak, nonatomic) IBOutlet UILabel *lblFlow1;
//@property (weak, nonatomic) IBOutlet UILabel *lblTotalPrice1;
@property (weak, nonatomic) IBOutlet UILabel *lblExpireDays1;

@property (weak, nonatomic) IBOutlet UIButton *btnOrderStatus1;

@property (weak, nonatomic) IBOutlet UIImageView *ivLogoPic2;
@property (weak, nonatomic) IBOutlet UILabel *lblFlow2;
//@property (weak, nonatomic) IBOutlet UILabel *lblTotalPrice2;
@property (weak, nonatomic) IBOutlet UILabel *lblExpireDays2;

@property (weak, nonatomic) IBOutlet UIButton *btnOrderStatus2;

@property (weak, nonatomic) IBOutlet UIImageView *ivLogoPic3;
@property (weak, nonatomic) IBOutlet UILabel *lblFlow3;
//@property (weak, nonatomic) IBOutlet UILabel *lblTotalPrice3;
@property (weak, nonatomic) IBOutlet UILabel *lblExpireDays3;

@property (weak, nonatomic) IBOutlet UIButton *btnOrderStatus3;
@property (weak, nonatomic) IBOutlet UIView *orderFoot1;
@property (weak, nonatomic) IBOutlet UIView *orderFoot2;

@property (readwrite) NSArray *arrOrderList;
@property (nonatomic, strong) UIButton *leftButton;

//@property (nonatomic, copy) NSString *simtype;

/*通讯录*/
@property (nonatomic,strong) NSArray *contactsDataArr;//数据源

@property (weak, nonatomic) IBOutlet UIView *sportView;

- (IBAction)viewAllOrders:(id)sender;

- (IBAction)viewAllContury:(id)sender;


@end
