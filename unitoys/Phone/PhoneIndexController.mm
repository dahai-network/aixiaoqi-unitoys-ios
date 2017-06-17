
//  PhoneIndexController.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "PhoneIndexController.h"
#import "HLTitlesView.h"
#import "global.h"
#import "PhoneRecordController.h"
#import "MessageRecordController.h"
#import "NewMessageViewController.h"
#import "UNDataTools.h"
#import "BlueToothDataManager.h"
#import "StatuesViewDetailViewController.h"
#import "BindDeviceViewController.h"
#import "UITabBar+UNRedTip.h"
#import "UNDatabaseTools.h"

@interface PhoneIndexController ()

@property (nonatomic, weak) HLTitlesView *titleView;


@property (nonatomic, strong)UIView *statuesView;
@property (nonatomic, strong)UILabel *statuesLabel;
@property (nonatomic, strong)UIView *registProgressView;
@end

@implementation PhoneIndexController

- (instancetype)init
{
    if (self = [super init]) {
        [self setupViewChildControllers];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self setupViewChildControllers];
    }
    return self;
}

//为了提前注册,需要在创建时初始化子控制器
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setupViewChildControllers];
    }
    return self;
}

- (void)viewDidLoad {
    if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]   || ![BlueToothDataManager shareManager].isShowStatuesView) {
        [UNDataTools sharedInstance].tipStatusHeight = 0;
    }else{
        [UNDataTools sharedInstance].tipStatusHeight = STATUESVIEWHEIGHT;
    }
    [super viewDidLoad];
    [self initTipStatuBar];
    
    [self setupViewControllers];
    [self setUpTitlesView];
    //更新tabbar红点
    [self initUnreadMessage];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(phoneTabbarDoubleClick:) name:@"PhoneTabbarDoubleClick" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(phoneTipMessageStatuChange) name:@"PhoneUnReadMessageStatuChange" object:nil];
    
}

- (void)currentStatueChangeAndChangeHeight {
    [self changeStatueViewHeightWithString:[BlueToothDataManager shareManager].statuesTitleString];
}

- (void)changeStatueViewHeightWithString:(NSString *)statueStr {
    [self setStatuesLabelTextWithLabel:self.statuesLabel String:statueStr];
    if ([statueStr isEqualToString:HOMESTATUETITLE_SIGNALSTRONG] || ![BlueToothDataManager shareManager].isShowStatuesView) {
        self.statuesView.un_height = 0;
        self.registProgressView.un_width = 0;
    } else {
        if (![statueStr isEqualToString:HOMESTATUETITLE_REGISTING]) {
            self.registProgressView.un_width = 0;
        }
        self.statuesView.un_height = STATUESVIEWHEIGHT;
    }
    if ([UNDataTools sharedInstance].tipStatusHeight != self.statuesView.un_height) {
        self.pageViewController.view.un_top = self.statuesView.un_height;
        self.pageViewController.view.un_height = self.view.un_height - self.statuesView.un_height - 49;
        [UNDataTools sharedInstance].tipStatusHeight = self.statuesView.un_height;
        //        [UNDataTools sharedInstance].pageViewHeight = self.pageViewController.view.un_height;
        [UNDataTools sharedInstance].pageViewHeight = kScreenHeightValue - 64 - self.statuesView.un_height - 49;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TipStatuBarHeightChange" object:nil];
    }
}

- (void)initTipStatuBar
{
    //添加状态栏
    self.statuesView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, STATUESVIEWHEIGHT)];
    self.statuesView.backgroundColor = UIColorFromRGB(0xffbfbf);
    //添加手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(jumpToShowDetail)];
    [self.statuesView addGestureRecognizer:tap];
    //添加百分比
    if ([[BlueToothDataManager shareManager].stepNumber intValue] != 0 && [[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_REGISTING]) {
        int longStr = [[BlueToothDataManager shareManager].stepNumber intValue];
        CGFloat progressWidth;
        if ([[BlueToothDataManager shareManager].operatorType intValue] == 1 || [[BlueToothDataManager shareManager].operatorType intValue] == 2) {
            progressWidth = kScreenWidthValue *(longStr/160.00);
        } else if ([[BlueToothDataManager shareManager].operatorType intValue] == 3) {
            progressWidth = kScreenWidthValue *(longStr/340.00);
        } else {
            progressWidth = 0;
        }
        self.registProgressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, progressWidth, STATUESVIEWHEIGHT)];
    } else {
        self.registProgressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, STATUESVIEWHEIGHT)];
    }
    self.registProgressView.backgroundColor = UIColorFromRGB(0xffa0a0);
    [self.statuesView addSubview:self.registProgressView];
    //添加图片
    UIImageView *leftImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_bc"]];
    leftImg.frame = CGRectMake(15, (STATUESVIEWHEIGHT-STATUESVIEWIMAGEHEIGHT)/2, STATUESVIEWIMAGEHEIGHT, STATUESVIEWIMAGEHEIGHT);
    [self.statuesView addSubview:leftImg];
    //添加label
    self.statuesLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftImg.frame)+5, 0, kScreenWidthValue-30-leftImg.frame.size.width, STATUESVIEWHEIGHT)];
//    self.statuesLabel.text = [BlueToothDataManager shareManager].statuesTitleString;
    [self setStatuesLabelTextWithLabel:self.statuesLabel String:[BlueToothDataManager shareManager].statuesTitleString];
    self.statuesLabel.font = [UIFont systemFontOfSize:14];
    self.statuesLabel.textColor = UIColorFromRGB(0x999999);
    [self.statuesView addSubview:self.statuesLabel];
    self.statuesView.clipsToBounds = YES;
    [self.view addSubview:self.statuesView];
    if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]  || ![BlueToothDataManager shareManager].isShowStatuesView) {
        self.statuesView.un_height = 0;
        self.registProgressView.un_width = 0;
        [UNDataTools sharedInstance].tipStatusHeight = self.statuesView.un_height;
    }
    
    self.pageViewController.view.frame = CGRectMake(0, self.statuesView.frame.size.height, kScreenWidthValue, kScreenHeightValue-49-self.statuesView.frame.size.height);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statuBarHeightChange:) name:@"changeStatuesViewLable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showRegistProgress:) name:@"changeStatue" object:nil];//改变状态和百分比
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentStatueChangeAndChangeHeight) name:@"currentStatueChangedAndHeightChange" object:@"currentStatueChangedAndHeightChange"];
}

#pragma mark 手势点击事件
- (void)jumpToShowDetail {
    if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_REGISTING] || [[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_NOTCONNECTED]) {
        if ([BlueToothDataManager shareManager].isBounded) {
            //有绑定
            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
            BindDeviceViewController *bindDeviceViewController = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
            if (bindDeviceViewController) {
                self.tabBarController.tabBar.hidden = YES;
                bindDeviceViewController.hintStrFirst = [BlueToothDataManager shareManager].statuesTitleString;
                [self.navigationController pushViewController:bindDeviceViewController animated:YES];
            }
        }
    } else {
        StatuesViewDetailViewController *statuesViewDetailVC = [[StatuesViewDetailViewController alloc] init];
        [self.navigationController pushViewController:statuesViewDetailVC animated:YES];
    }
}

- (void)statuBarHeightChange:(NSNotification *)noti
{
    UNDebugLogVerbose(@"statuBarHeightChange----%@", noti.object);
    [self changeStatueViewHeightWithString:noti.object];
}

- (void)showRegistProgress:(NSNotification *)sender {
    NSString *senderStr = [NSString stringWithFormat:@"%@", sender.object];
    UNDebugLogVerbose(@"状态栏文字 --> %@, %s, %d", senderStr, __FUNCTION__, __LINE__);
    if (![BlueToothDataManager shareManager].isRegisted && [BlueToothDataManager shareManager].isBeingRegisting) {
        [self countAndShowRegistPercentage:senderStr];
    } else {
        UNDebugLogVerbose(@"注册成功的时候处理");
    }
}

- (void)countAndShowRegistPercentage:(NSString *)senderStr {
    if ([[BlueToothDataManager shareManager].operatorType intValue] == 1 || [[BlueToothDataManager shareManager].operatorType intValue] == 2) {
        if ([senderStr intValue] < 160) {
            float count = (float)[senderStr intValue]/160;
            self.registProgressView.un_width = kScreenWidthValue * count;
        } else {
            self.registProgressView.un_width = kScreenWidthValue * 0.99;
        }
    } else if ([[BlueToothDataManager shareManager].operatorType intValue] == 3) {
        if ([senderStr intValue] < 340) {
            float count = (float)[senderStr intValue]/340;
            self.registProgressView.un_width = kScreenWidthValue * count;
        } else {
            self.registProgressView.un_width = kScreenWidthValue * 0.99;
        }
    } else {
        self.registProgressView.un_width = 0;
    }
}

- (void)setupViewControllers
{
    if (!self.viewControllers) {
        [self setupViewChildControllers];
    }
}

- (BOOL)initEngine
{
    if (self.viewControllers.count) {
        if ([self.viewControllers.firstObject isKindOfClass:[PhoneRecordController class]]) {
            PhoneRecordController *vc1 = self.viewControllers.firstObject;
            return [vc1 initEngine];
        }
    }
    return NO;
}
- (void)unregister
{
    if (self.viewControllers.count) {
        if ([self.viewControllers.firstObject isKindOfClass:[PhoneRecordController class]]) {
            PhoneRecordController *vc1 = self.viewControllers.firstObject;
            [vc1 unregister];
        }
    }
}

- (void)initUnreadMessage
{
    NSArray *arrMessageRecord = [[UNDatabaseTools sharedFMDBTools] getMessageListsWithPage:0];
    
    //添加未读短信
    for (NSDictionary *dicMessageRecord in arrMessageRecord) {
        if (![dicMessageRecord[@"IsRead"] boolValue]) {
            NSString *currentPhone;
            if ([[dicMessageRecord objectForKey:@"IsSend"] boolValue]) {
                //己方发送
                currentPhone = [dicMessageRecord objectForKey:@"To"];
            }else{
                //对方发送
                currentPhone = [dicMessageRecord objectForKey:@"Fm"];
            }
            if (![[UNDataTools sharedInstance].currentUnreadSMSPhones containsObject:currentPhone]) {
                [[UNDataTools sharedInstance].currentUnreadSMSPhones addObject:currentPhone];
            }
        }
    }
    if ([UNDataTools sharedInstance].currentUnreadSMSPhones.count) {
        [UNDataTools sharedInstance].isHasUnreadSMS = YES;
    }else{
        [UNDataTools sharedInstance].isHasUnreadSMS = NO;
    }
    
    [self phoneTipMessageStatuChange];
}

//设置tabbar红点
- (void)phoneTipMessageStatuChange
{
    BOOL isHasMessage = NO;
    if ([UNDataTools sharedInstance].isHasMissCall) {
        isHasMessage = YES;
        [self.titleView showRedTipWithIndex:0];
    }else{
        [self.titleView hiddenRedTipWithIndex:0];
    }
    
    if ([UNDataTools sharedInstance].isHasUnreadSMS) {
        isHasMessage = YES;
        [self.titleView showRedTipWithIndex:1];
    }else{
        [self.titleView hiddenRedTipWithIndex:1];
    }
    if (isHasMessage) {
        [self.tabBarController.tabBar showBadgeOnItemIndex:1];
    }else{
        [self.tabBarController.tabBar hideBadgeOnItemIndex:1];
    }
//    if ([UNDataTools sharedInstance].isHasMissCall || [UNDataTools sharedInstance].isHasUnreadSMS) {
//        [self.tabBarController.tabBar showBadgeOnItemIndex:1];
//    }else{
//        [self.tabBarController.tabBar hideBadgeOnItemIndex:1];
//    }
}

//设置导航栏
- (void)setUpTitlesView
{
    kWeakSelf
    HLTitlesView *titlesView = [HLTitlesView titlesViewWithTitles:@[@"通话历史", @"短信记录"]  Margin:15];
    titlesView.titlesButtonAction = ^(UIButton *button){
        UNDebugLogVerbose(@"%zd", button.tag);
        [weakSelf setCurrentShowView:button.tag];
    };
    self.titleView = titlesView;
    self.navigationItem.titleView = titlesView;
}

- (void)setCurrentShowView:(NSInteger)tag
{
    if (self.viewControllers.count > tag) {
        NSArray *startController = @[self.viewControllers[tag]];
        [self.pageViewController setViewControllers:startController
                                          direction: UIPageViewControllerNavigationDirectionReverse
                                           animated:NO
                                         completion:nil];
    }else{
        NSArray *startController = @[self.viewControllers.lastObject];
        [self.pageViewController setViewControllers:startController
                                          direction: UIPageViewControllerNavigationDirectionReverse
                                           animated:NO
                                         completion:nil];
    }
}

- (void)phoneTabbarDoubleClick:(NSNotification *)noti
{
//    [self.titleView setSelectButtonWithTag:1];
    [self.titleView changeCurrentSelectButton];
}

- (void)initRightButton
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit_info_nor"] style:UIBarButtonItemStyleDone target:self action:@selector(rightButtonAction)];
}

- (void)rightButtonAction
{
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Phone" bundle:nil];
    NewMessageViewController *newMessageViewController = [mainStory instantiateViewControllerWithIdentifier:@"newMessageViewController"];
    if (newMessageViewController) {
        //writeMessageViewController.destNumber = [dicPackage objectForKey:@"PackageId"];
        [self.navigationController pushViewController:newMessageViewController animated:YES];
    }
}

//#pragma mark
//#pragma mark Override
- (void)setupViewChildControllers
{
    kWeakSelf
    PhoneRecordController *vc1  = [[PhoneRecordController alloc] init];
    vc1.nav = self.navigationController;
    vc1.isHideTitleViewBlock = ^(BOOL isHidden) {
        weakSelf.titleView.hidden = isHidden;
    };
    MessageRecordController *vc2  = [[MessageRecordController alloc] init];
    vc2.nav = self.navigationController;
    self.viewControllers = @[vc1, vc2];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)isShowLeftButton
{
    return NO;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
