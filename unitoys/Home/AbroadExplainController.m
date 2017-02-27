//
//  AbroadExplainController.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "AbroadExplainController.h"
#import "ExplainDetailsChildController.h"
#import "BlueToothDataManager.h"

@interface AbroadExplainController ()<UIScrollViewDelegate>

@property (nonatomic, weak) UIScrollView *contentScrollView;
@property (nonatomic, weak) UIPageControl *pageControl;

@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation AbroadExplainController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initSubViews];
}

- (void)initSubViews
{
    [self initData];
    [self setUpScrollView];
    [self setUpChildViews];
}

- (void)initData
{
    self.dataArray = [NSMutableArray array];
    if (self.currentExplainType == ExplainTypeAbroad) {
        self.title = @"在境外";
        NSDictionary *page1 = @{
                                @"nameTitle" : @"插电话卡",
                                @"detailTitle" : @"将爱小器国际卡插入手机中，然后将您的国内电话卡插入到手环中。",
                                @"explainImage" : @"",
                                };
        NSDictionary *page2 = @{
                                @"nameTitle" : @"设置APN",
                                @"detailTitle" : @"打开系统的APN设置界面，点击新建APN，然后在“名称”和“APN”行都输入263，点击保存，最后启用该APN。",
                                @"explainImage" : @"",
                                @"buttonTitle" : @"打开APN设置",
                                @"buttonAction" : @"apnSettingAction",
                                };
        NSDictionary *page3 = @{
                                @"nameTitle" : @"关闭4G网络。",
                                @"detailTitle" : @"在手机的系统设置的网络连接方式中，关闭4G网络，选择2G或3G上网。",
                                @"explainImage" : @"",
                                @"buttonTitle" : @"打开系统设置",
                                @"buttonAction" : @"gotoSystemSettingAction",
                                };
        NSDictionary *page4 = @{
                                @"nameTitle" : @"开启数据漫游",
                                @"detailTitle" : @"在手机的系统设置的数据漫游管理界面，开启数据漫游。此时手机可以上网，打开浏览器测试下。",
                                @"explainImage" : @"",
                                @"buttonTitle" : @"打开系统设置",
                                @"buttonAction" : @"gotoSystemSettingAction",
                                };
        NSDictionary *page5 = @{
                                @"nameTitle" : @"接打电话，收发短信",
                                @"detailTitle" : @"确保手机能够上网后，重启APP，点击主页走上街按钮，查看手环内电话卡的状态，如果信号良好，即可接打电话，收发短信。",
                                @"explainImage" : @"",
                                };
        //根据类型确定需要添加的页面
        [self.dataArray addObject:page1];
        if (self.isApn) {
            [self.dataArray addObject:page2];
        }
        if (self.isSupport4G) {
            [self.dataArray addObject:page3];
        }
        [self.dataArray addObject:page4];
        [self.dataArray addObject:page5];

    }else if (self.currentExplainType == ExplainTypeInternal){
        self.title = @"回国后";
        NSDictionary *page1 = @{
                                @"nameTitle" : @"换卡",
                                @"detailTitle" : @"将爱小器国际卡从手机中取出，然后将自己的电话卡插回手机。",
                                @"explainImage" : @"",
                                };
        NSDictionary *page2 = @{
                                @"nameTitle" : @"删除APN",
                                @"detailTitle" : @"打开系统的APN设置界面，选择新建的名为“263”的APN，然后删除。",
                                @"explainImage" : @"",
                                @"buttonTitle" : @"打开APN设置",
                                @"buttonAction" : @"apnSettingAction",
                                };
        NSDictionary *page3 = @{
                                @"nameTitle" : @"开启4G网络。",
                                @"detailTitle" : @"在手机的系统设置的网络连接方式中，选择4G网络。",
                                @"explainImage" : @"",
                                @"buttonTitle" : @"打开系统设置",
                                @"buttonAction" : @"gotoSystemSettingAction",
                                };
        NSDictionary *page4 = @{
                                @"nameTitle" : @"关闭数据漫游",
                                @"detailTitle" : @"在手机的系统设置的数据漫游管理界面，关闭数据漫游。",
                                @"explainImage" : @"",
                                @"buttonTitle" : @"打开系统设置",
                                @"buttonAction" : @"gotoSystemSettingAction",
                                };
        //根据类型确定需要添加的页面
        [self.dataArray addObject:page1];
        if (self.isApn) {
            [self.dataArray addObject:page2];
        }
        if (self.isSupport4G) {
            [self.dataArray addObject:page3];
        }
        [self.dataArray addObject:page4];
    }
    
//    self.dataArray = @[
//                       @{
//                           @"nameTitle" : @"插电话卡",
//                           @"detailTitle" : @"将爱小器国际卡插入手机中，然后将您的国内电话卡插入到手环中。",
//                           @"explainImage" : @"",
//                           },
//                       @{
//                           @"nameTitle" : @"设置APN",
//                           @"detailTitle" : @"打开系统的APN设置界面，点击新建APN，然后在“名称”和“APN”行都输入263，点击保存，最后启用该APN。",
//                           @"explainImage" : @"",
//                           @"buttonTitle" : @"打开APN设置",
//                           @"buttonAction" : @"apnSettingAction",
//                           },
//                       @{
//                           @"nameTitle" : @"关闭4G网络。",
//                           @"detailTitle" : @"在手机的系统设置的网络连接方式中，关闭4G网络，选择2G或3G上网。",
//                           @"explainImage" : @"",
//                           @"buttonTitle" : @"打开系统设置",
//                           @"buttonAction" : @"gotoSystemSettingAction",
//                           },
//                       @{
//                           @"nameTitle" : @"开启数据漫游",
//                           @"detailTitle" : @"在手机的系统设置的数据漫游管理界面，开启数据漫游。此时手机可以上网，打开浏览器测试下。",
//                           @"explainImage" : @"",
//                           @"buttonTitle" : @"打开系统设置",
//                           @"buttonAction" : @"gotoSystemSettingAction",
//                           },
//                       @{
//                           @"nameTitle" : @"接打电话，收发短信",
//                           @"detailTitle" : @"确保手机能够上网后，重启APP，点击主页走上街按钮，查看手环内电话卡的状态，如果信号良好，即可接打电话，收发短信。",
//                           @"explainImage" : @"",
//                           },
//                       ];
}

- (void)setUpChildViews
{
    for (NSInteger i =0; i < self.dataArray.count; i++) {
        NSDictionary *dict = self.dataArray[i];
        ExplainDetailsChildController *explainDetailsVc = [[ExplainDetailsChildController alloc] init];
        explainDetailsVc.view.frame = CGRectMake(i * self.contentScrollView.width, 0, self.contentScrollView.width, self.contentScrollView.height);
        explainDetailsVc.nameLabel.text = dict[@"nameTitle"];
        explainDetailsVc.detailLabel.text = dict[@"detailTitle"];
        if (dict[@"explainImage"]) {
            explainDetailsVc.explainImageView.image = [UIImage imageNamed:dict[@"explainImage"]];
        }
        if (dict[@"buttonTitle"]) {
            explainDetailsVc.gotoSystemButton.hidden = NO;
            [explainDetailsVc.gotoSystemButton setTitle:dict[@"buttonTitle"] forState:UIControlStateNormal];
            NSString *actionStr = dict[@"buttonAction"];
            SEL action = NSSelectorFromString(actionStr);
            if ([self respondsToSelector:action]) {
                [explainDetailsVc.gotoSystemButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
            }
        }else{
            explainDetailsVc.gotoSystemButton.hidden = YES;
        }
        [self.contentScrollView addSubview:explainDetailsVc.view];
    }
}

- (void)setUpScrollView
{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, kScreenHeightValue - 64)];
    self.contentScrollView = scrollView;
    self.contentScrollView.contentSize = CGSizeMake(self.dataArray.count * self.contentScrollView.width, 0);
    self.contentScrollView.pagingEnabled = YES;
    self.contentScrollView.showsHorizontalScrollIndicator = NO;
    self.contentScrollView.showsVerticalScrollIndicator = NO;
    self.contentScrollView.bounces = NO;
    self.contentScrollView.delegate = self;
    [self.view addSubview:self.contentScrollView];
    
    UIPageControl *pageControl = [[UIPageControl alloc] init];
    self.pageControl = pageControl;
    pageControl.centerX = self.view.width * 0.5;
    pageControl.bottom = self.view.height - 100;
    pageControl.numberOfPages = self.dataArray.count;
    pageControl.currentPage = 0;
    pageControl.userInteractionEnabled = NO;
    pageControl.pageIndicatorTintColor = UIColorFromRGB(0xf2f2f2);
    pageControl.currentPageIndicatorTintColor = UIColorFromRGB(0x249CD3);
    [self.view addSubview:pageControl];
}

- (void)apnSettingAction
{
    //访问描述文件
    NSString *textURL = [NSString stringWithFormat:@"http://localhost:%@/aixiaoqi.mobileconfig", [BlueToothDataManager shareManager].localServicePort];
    NSURL *cleanURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", textURL]];
    NSLog(@"访问的连接为 -- %@", cleanURL);
    [[UIApplication sharedApplication] openURL:cleanURL];
    NSDictionary *info = @{@"title": @"访问"};
    [[UIApplication sharedApplication] openURL:cleanURL options:info completionHandler:nil];
}

- (void)gotoSystemSettingAction
{
    //打开app设置界面
//    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    //打开描述文件界面
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-prefs:root=General&path=ManagedConfigurationList"]];
    //打开系统设置界面
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-prefs:root=General&path=Network "]];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger curentPage = (NSInteger)scrollView.contentOffset.x / scrollView.bounds.size.width;
    self.pageControl.currentPage = curentPage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end