
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

@interface PhoneIndexController ()

@property (nonatomic, weak) HLTitlesView *titleView;


@property (nonatomic, strong)UIView *statuesView;
@property (nonatomic, strong)UILabel *statuesLabel;
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
    if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
        [UNDataTools sharedInstance].tipStatusHeight = 0;
    }else{
        [UNDataTools sharedInstance].tipStatusHeight = STATUESVIEWHEIGHT;
    }
    [super viewDidLoad];
    [self initTipStatuBar];
    
    [self setupViewControllers];
    [self setUpTitlesView];
}

- (void)initTipStatuBar
{
    //添加状态栏
    self.statuesView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, STATUESVIEWHEIGHT)];
    self.statuesView.backgroundColor = UIColorFromRGB(0xffbfbf);
    //添加手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(jumpToShowDetail)];
    [self.statuesView addGestureRecognizer:tap];
    UIImageView *leftImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_bc"]];
    leftImg.frame = CGRectMake(15, (STATUESVIEWHEIGHT-STATUESVIEWIMAGEHEIGHT)/2, STATUESVIEWIMAGEHEIGHT, STATUESVIEWIMAGEHEIGHT);
    [self.statuesView addSubview:leftImg];
    self.statuesLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftImg.frame)+5, 0, kScreenWidthValue-30-leftImg.frame.size.width, STATUESVIEWHEIGHT)];
    self.statuesLabel.text = [BlueToothDataManager shareManager].statuesTitleString;
    self.statuesLabel.font = [UIFont systemFontOfSize:14];
    self.statuesLabel.textColor = UIColorFromRGB(0x999999);
    [self.statuesView addSubview:self.statuesLabel];
    self.statuesView.clipsToBounds = YES;
    [self.view addSubview:self.statuesView];
    if ([[BlueToothDataManager shareManager].statuesTitleString isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
        self.statuesView.un_height = 0;
        [UNDataTools sharedInstance].tipStatusHeight = self.statuesView.un_height;
    }
    
    self.pageViewController.view.frame = CGRectMake(0, self.statuesView.frame.size.height, kScreenWidthValue, kScreenHeightValue-49-self.statuesView.frame.size.height);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statuBarHeightChange:) name:@"changeStatuesViewLable" object:nil];
}

#pragma mark 手势点击事件
- (void)jumpToShowDetail {
    StatuesViewDetailViewController *statuesViewDetailVC = [[StatuesViewDetailViewController alloc] init];
    [self.navigationController pushViewController:statuesViewDetailVC animated:YES];
}

- (void)statuBarHeightChange:(NSNotification *)noti
{
    NSLog(@"statuBarHeightChange----%@", noti.object);
    self.statuesLabel.text = noti.object;
    if ([noti.object isEqualToString:HOMESTATUETITLE_SIGNALSTRONG]) {
        self.statuesView.un_height = 0;
    } else {
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
//- (void)loadMessage
//{
//    
//}

//设置导航栏
- (void)setUpTitlesView
{
    kWeakSelf
    HLTitlesView *titlesView = [HLTitlesView titlesViewWithTitles:@[@"通话历史", @"短信记录"]  Margin:15];
    titlesView.titlesButtonAction = ^(UIButton *button){
        NSLog(@"%ld", button.tag);
//        if (button.tag == 0) {
//            self.navigationItem.rightBarButtonItem = nil;
//        }else{
//            [self initRightButton];
//        }
        NSArray *startController = @[weakSelf.viewControllers[button.tag]];
        [weakSelf.pageViewController setViewControllers:startController
                                              direction: UIPageViewControllerNavigationDirectionReverse
                                               animated:NO
                                             completion:nil];
    };
    self.titleView = titlesView;
    self.navigationItem.titleView = titlesView;
//    [self.navigationController.navigationBar addSubview:titlesView];
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
