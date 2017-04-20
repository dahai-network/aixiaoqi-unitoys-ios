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
#import "HTTPServer.h"
#import "UNDataTools.h"

@interface AbroadExplainController ()<UIScrollViewDelegate>

//@property (nonatomic, weak) UIScrollView *contentScrollView;
//@property (nonatomic, weak) UIPageControl *pageControl;

@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) HTTPServer *localHttpServer;//本地服务器
@property (nonatomic, strong) NSMutableArray *pagesVCArray;

@end

@implementation AbroadExplainController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initSubViews];
    [self performSelector:@selector(configLocalHttpServer) withObject:nil afterDelay:1];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    [_localHttpServer stop];
}

#pragma mark - 本地服务器
#pragma mark - 搭建本地服务器 并且启动
- (void)configLocalHttpServer{
    _localHttpServer = [[HTTPServer alloc] init];
    [_localHttpServer setType:@"_http.tcp"];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSLog(@"文件目录 -- %@",webPath);
    
    if (![fileManager fileExistsAtPath:webPath]){
        NSLog(@"File path error!");
    }else{
        NSString *webLocalPath = webPath;
        [_localHttpServer setDocumentRoot:webLocalPath];
        NSLog(@"webLocalPath:%@",webLocalPath);
        [self startServer];
    }
}

- (void)startServer {
    NSError *error;
    if([_localHttpServer start:&error]){
        NSLog(@"Started HTTP Server on port %hu", [_localHttpServer listeningPort]);
        [BlueToothDataManager shareManager].localServicePort = [NSString stringWithFormat:@"%d",[_localHttpServer listeningPort]];
    } else {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
}

- (void)initSubViews
{
    [self initData];
//    [self setUpScrollView];
//    [self setUpChildViews];
}

- (void)initData
{
    self.dataArray = [NSMutableArray array];
    self.pagesVCArray = [NSMutableArray array];
    if (self.currentExplainType == ExplainTypeAbroad) {
        self.title = INTERNATIONALSTRING(@"出境后使用引导");
        NSDictionary *page1 = @{
                                @"nameTitle" : INTERNATIONALSTRING(@"插电话卡"),
                                @"detailTitle" : INTERNATIONALSTRING(@"将爱小器国际卡插入手机中,然后将您的国内电话卡插入到手环或双待王中"),
                                @"explainImage" : @"set_afteroutstep1",
                                @"pageType" : @(1),
                                };
        
        NSDictionary *page2 = @{
                                @"nameTitle" : INTERNATIONALSTRING(@"安装APN"),
                                @"detailTitle" : INTERNATIONALSTRING(@"点击“安装APN”按钮，跳转到系统设置的安装APN界面，然后点击右上角“安装”按钮，同意安装。"),
                                @"explainImage" : @"set_afteroutstep2",
                                @"buttonTitle" : INTERNATIONALSTRING(@"安装APN"),
                                @"buttonAction" : @"apnSettingAction",
                                @"pageType" : @(1),
                                };
        
        NSString *page3Title;
        NSString *page3ImageStr;
        if (self.isSupport4G) {
            page3Title = INTERNATIONALSTRING(@"点击按钮会跳转到系统设置，点击\"蜂窝移动网络数据选项\"然后开启数据漫游,开启4G网络(或选择4G网络)");
            page3ImageStr = @"";
        }else{
            page3Title = INTERNATIONALSTRING(@"点击按钮会跳转到系统设置，点击\"蜂窝移动网络数据选项\"然后开启数据漫游,关闭4G网络(或选择3G网络)");
            page3ImageStr = @"";
        }
        NSDictionary *page3 = @{
                                @"nameTitle" : INTERNATIONALSTRING(@"修改移动网络设置"),
                                @"detailTitle" : page3Title,
                                @"explainImage" : page3ImageStr,
                                @"buttonTitle" : INTERNATIONALSTRING(@"移动网络设置"),
                                @"buttonAction" : @"gotoSystemSettingAction",
                                @"pageType" : @(1),
                                };
         
        NSDictionary *page4 = @{
                                @"nameTitle" : INTERNATIONALSTRING(@"接打电话，收发短信"),
                                @"detailTitle" : INTERNATIONALSTRING(@"确保手机能够上网后，重启APP，点击主页左上角按钮，查看手环内电话卡的状态，如果信号良好，即可接打电话，收发短信。"),
                                @"pageType" : @(2),
                                };
        //根据类型确定需要添加的页面
        [self.dataArray addObject:page1];
        if (self.isApn) {
            [self.dataArray addObject:page2];
        }
        [self.dataArray addObject:page3];
        [self.dataArray addObject:page4];

    }
//    else if (self.currentExplainType == ExplainTypeInternal){
//        self.title = INTERNATIONALSTRING(@"回国后");
//        NSDictionary *page1 = @{
//                                @"nameTitle" : INTERNATIONALSTRING(@"插电话卡"),
//                                @"detailTitle" : INTERNATIONALSTRING(@"手环和手机内置的SIM卡交换位置。"),
//                                @"explainImage" : @"set_afteroutstep1",
//                                };
//        NSDictionary *page2 = @{
//                                @"nameTitle" : INTERNATIONALSTRING(@"删除APN"),
//                                @"detailTitle" : INTERNATIONALSTRING(@"点击“删除APN”按钮，跳转到系统设置的“描述文件”界面，选择“爱小器APN”，再点击“删除描述文件”。"),
//                                @"explainImage" : @"set_afteroutstep5",
//                                @"buttonTitle" : INTERNATIONALSTRING(@"删除APN"),
//                                @"buttonAction" : @"apnDeleteAction",
//                                };
//        NSDictionary *page3 = @{
//                                @"nameTitle" : INTERNATIONALSTRING(@"开启4G网络。"),
//                                @"detailTitle" : INTERNATIONALSTRING(@"在手机的系统设置的网络连接方式中，选择4G网络。"),
//                                @"explainImage" : @"set_afteroutstep3",
//                                @"buttonTitle" : INTERNATIONALSTRING(@"打开系统设置"),
//                                @"buttonAction" : @"gotoSystemSettingAction",
//                                };
//        NSDictionary *page4 = @{
//                                @"nameTitle" : INTERNATIONALSTRING(@"关闭数据漫游"),
//                                @"detailTitle" : INTERNATIONALSTRING(@"在手机的系统设置的数据漫游管理界面，关闭数据漫游。"),
//                                @"explainImage" : @"set_afteroutstep4",
//                                @"buttonTitle" : INTERNATIONALSTRING(@"打开系统设置"),
//                                @"buttonAction" : @"gotoSystemSettingAction",
//                                };
//        //根据类型确定需要添加的页面
//        [self.dataArray addObject:page1];
//        if (self.isApn) {
//            [self.dataArray addObject:page2];
//        }
//        if (self.isSupport4G) {
//            [self.dataArray addObject:page3];
//        }
//        [self.dataArray addObject:page4];
//    }
    
}

//- (void)setUpChildViews
//{
//    NSArray *pageNumbers = @[@"❶", @"❷", @"❸", @"❹", @"❺"];
//    for (NSInteger i =0; i < self.dataArray.count; i++) {
//        NSDictionary *dict = self.dataArray[i];
//        ExplainDetailsChildController *explainDetailsVc = [[ExplainDetailsChildController alloc] init];
//        explainDetailsVc.view.frame = CGRectMake(i * self.contentScrollView.width, 0, self.contentScrollView.width, self.contentScrollView.height);
//        explainDetailsVc.pageNumber.text = pageNumbers[i];
//        
//        if (dict[@"nameTitle"]) {
//            explainDetailsVc.nameLabel.hidden = NO;
//            explainDetailsVc.nameLabel.text = dict[@"nameTitle"];
//        }else{
//            explainDetailsVc.nameLabel.hidden = YES;
//            explainDetailsVc.imageTopMargin.constant -= 20;
//        }
//        if (dict[@"detailTitle"]) {
//            explainDetailsVc.detailLabel.hidden = NO;
//            explainDetailsVc.detailLabel.text = dict[@"detailTitle"];
//        }else{
//            explainDetailsVc.detailLabel.hidden = YES;
//            explainDetailsVc.imageTopMargin.constant -= 50;
//        }
//        
//        if (dict[@"buttonTitle"]) {
//            explainDetailsVc.gotoSystemButton.hidden = NO;
//            [explainDetailsVc.gotoSystemButton setTitle:dict[@"buttonTitle"] forState:UIControlStateNormal];
//            NSString *actionStr = dict[@"buttonAction"];
//            SEL action = NSSelectorFromString(actionStr);
//            if ([self respondsToSelector:action]) {
//                [explainDetailsVc.gotoSystemButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
//            }
//        }else{
//            explainDetailsVc.gotoSystemButton.hidden = YES;
//            explainDetailsVc.imageTopMargin.constant -= 50;
//        }
//        
//        if (dict[@"explainImage"]) {
//            explainDetailsVc.explainImageView.hidden = NO;
//            
//            UIImage *image = [UIImage imageNamed:dict[@"explainImage"]];
//            CGSize realSize;
//            CGSize imageSize = image.size;
//            CGFloat imageViewWidthMax = kScreenWidthValue - 40;
//            CGFloat imageViewHeightMax = kScreenHeightValue - 170 - 49 + (70 - explainDetailsVc.imageTopMargin.constant);
//            CGFloat imageScale = (CGFloat)imageSize.width / imageSize.height;
//            CGFloat imageViewScale = (CGFloat)imageViewWidthMax / imageViewHeightMax;
//            
//            if (imageViewScale > imageScale) {
//                realSize.height = imageViewHeightMax;
//                realSize.width = imageScale * imageViewHeightMax;
//            }else{
//                realSize.width = imageViewWidthMax;
//                realSize.height = imageViewWidthMax / imageScale;
//            }
//            explainDetailsVc.imageWidthConstraint.constant = realSize.width;
//            explainDetailsVc.imageHeightConstraint.constant = realSize.height;
//            explainDetailsVc.explainImageView.image = [UIImage imageNamed:dict[@"explainImage"]];
//        }else{
//            explainDetailsVc.explainImageView.hidden = YES;
//        }
//
//        [self.contentScrollView addSubview:explainDetailsVc.view];
//    }
//}

//- (void)setUpChildViews
//{
//    NSArray *pageNumbers = @[@"1", @"2", @"3", @"4"];
//    for (NSInteger i =0; i < self.dataArray.count; i++) {
//        NSDictionary *dict = self.dataArray[i];
//        if ([dict[@"pageType"] integerValue] == 1) {
//            ExplainDetailsChildController *explainDetailsVc = [[ExplainDetailsChildController alloc] init];
//            explainDetailsVc.pageNumber.text = pageNumbers[i];
//            explainDetailsVc.currentPage = i;
//            explainDetailsVc.totalPage = self.dataArray.count;
//            kWeakSelf
//            explainDetailsVc.nextStepActionBlock = ^(NSInteger currentPage, NSInteger totalPage) {
//                [weakSelf gotoNextPageWithCurrentPage:currentPage];
//            };
//            if (dict[@"nameTitle"]) {
//                explainDetailsVc.nameLabel.hidden = NO;
//                explainDetailsVc.nameLabel.text = dict[@"nameTitle"];
//            }else{
//                explainDetailsVc.nameLabel.hidden = YES;
//            }
//            if (dict[@"detailTitle"]) {
//                explainDetailsVc.detailLabel.hidden = NO;
//                explainDetailsVc.detailLabel.text = dict[@"detailTitle"];
//            }else{
//                explainDetailsVc.detailLabel.hidden = YES;
//            }
//            
//            if (dict[@"buttonTitle"]) {
//                explainDetailsVc.gotoSystemButton.hidden = NO;
//                [explainDetailsVc.gotoSystemButton setTitle:dict[@"buttonTitle"] forState:UIControlStateNormal];
//                NSString *actionStr = dict[@"buttonAction"];
//                SEL action = NSSelectorFromString(actionStr);
//                if ([self respondsToSelector:action]) {
//                    [explainDetailsVc.gotoSystemButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
//                }
//            }else{
//                explainDetailsVc.gotoSystemButton.hidden = YES;
//            }
//            
//            if (dict[@"explainImage"]) {
//                explainDetailsVc.explainImageView.hidden = NO;
//                explainDetailsVc.explainImageView.image = [UIImage imageNamed:dict[@"explainImage"]];
//            }else{
//                explainDetailsVc.explainImageView.hidden = YES;
//            }
//            [self.pagesVCArray addObject:explainDetailsVc];
//        }else{
//            ExplainDetailsChildController *explainDetailsVc = [[ExplainDetailsChildController alloc] init];
//            explainDetailsVc.pageNumber.text = pageNumbers[i];
//            explainDetailsVc.currentPage = i;
//            explainDetailsVc.totalPage = self.dataArray.count;
//            kWeakSelf
//            explainDetailsVc.nextStepActionBlock = ^(NSInteger currentPage, NSInteger totalPage) {
//                [weakSelf gotoNextPageWithCurrentPage:currentPage];
//            };
//            if (dict[@"nameTitle"]) {
//                explainDetailsVc.nameLabel.hidden = NO;
//                explainDetailsVc.nameLabel.text = dict[@"nameTitle"];
//            }else{
//                explainDetailsVc.nameLabel.hidden = YES;
//            }
//            if (dict[@"detailTitle"]) {
//                explainDetailsVc.detailLabel.hidden = NO;
//                explainDetailsVc.detailLabel.text = dict[@"detailTitle"];
//            }else{
//                explainDetailsVc.detailLabel.hidden = YES;
//            }
//            
//            if (dict[@"buttonTitle"]) {
//                explainDetailsVc.gotoSystemButton.hidden = NO;
//                [explainDetailsVc.gotoSystemButton setTitle:dict[@"buttonTitle"] forState:UIControlStateNormal];
//                NSString *actionStr = dict[@"buttonAction"];
//                SEL action = NSSelectorFromString(actionStr);
//                if ([self respondsToSelector:action]) {
//                    [explainDetailsVc.gotoSystemButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
//                }
//            }else{
//                explainDetailsVc.gotoSystemButton.hidden = YES;
//            }
//            
//            if (dict[@"explainImage"]) {
//                explainDetailsVc.explainImageView.hidden = NO;
//                explainDetailsVc.explainImageView.image = [UIImage imageNamed:dict[@"explainImage"]];
//            }else{
//                explainDetailsVc.explainImageView.hidden = YES;
//            }
//            [self.pagesVCArray addObject:explainDetailsVc];
//
//        }
//    }
//}

//- (void)gotoNextPageWithCurrentPage:(NSInteger)currentPage
//{
//    if (currentPage < self.pagesVCArray.count - 1) {
//        [self.navigationController pushViewController:self.pagesVCArray[currentPage + 1] animated:YES];
//    }else if (currentPage == self.pagesVCArray.count - 1){
//        UIViewController *popVc;
//        for (UIViewController *vc in self.navigationController.viewControllers) {
//            if ([vc isKindOfClass:NSClassFromString(@"AbroadPackageExplainController")]) {
//                popVc = vc;
//            }
//        }
//        if (popVc) {
//            [self.navigationController popToViewController:popVc animated:YES];
//        }
//    }
//}

//- (void)setUpScrollView
//{
//    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue, kScreenHeightValue - 64)];
//    self.contentScrollView = scrollView;
//    self.contentScrollView.contentSize = CGSizeMake(self.dataArray.count * self.contentScrollView.width, 0);
//    self.contentScrollView.pagingEnabled = YES;
//    self.contentScrollView.showsHorizontalScrollIndicator = NO;
//    self.contentScrollView.showsVerticalScrollIndicator = NO;
//    self.contentScrollView.bounces = NO;
//    self.contentScrollView.delegate = self;
//    [self.view addSubview:self.contentScrollView];
//    
//    UIPageControl *pageControl = [[UIPageControl alloc] init];
//    self.pageControl = pageControl;
//    pageControl.centerX = self.view.width * 0.5;
//    pageControl.bottom = self.view.height - 80;
//    pageControl.numberOfPages = self.dataArray.count;
//    pageControl.currentPage = 0;
//    pageControl.userInteractionEnabled = NO;
//    pageControl.pageIndicatorTintColor = UIColorFromRGB(0xf2f2f2);
//    pageControl.currentPageIndicatorTintColor = UIColorFromRGB(0x249CD3);
//    [self.view addSubview:pageControl];
//}

- (void)apnSettingAction
{
    //访问描述文件
    NSString *textURL = [NSString stringWithFormat:@"http://localhost:%@/%@.mobileconfig", [BlueToothDataManager shareManager].localServicePort, self.apnName];
    NSURL *cleanURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", textURL]];
    NSLog(@"访问的连接为 -- %@", cleanURL);
    if (kSystemVersionValue >= 10.0) {
        NSDictionary *info = @{@"title": @"访问"};
        [[UIApplication sharedApplication] openURL:cleanURL options:info completionHandler:nil];
    }else{
        [[UIApplication sharedApplication] openURL:cleanURL];
    }
    
}

- (void)apnDeleteAction
{
    //删除APN
    //打开描述文件界面
    if (kSystemVersionValue >= 10.0) {
        NSDictionary *info = @{@"title": @"访问"};
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-prefs:root=General&path=ManagedConfigurationList"] options:info completionHandler:nil];
    }else{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-prefs:root=General&path=ManagedConfigurationList"]];
    }
}

- (void)gotoSystemSettingAction
{
    //打开app设置界面
//    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    //打开系统设置界面
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"App-prefs:root=MOBILE_DATA_SETTINGS_ID"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-prefs:root=MOBILE_DATA_SETTINGS_ID"]];
    } else {
        NSLog(@"打不开");
    }
}


//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    NSInteger curentPage = (NSInteger)scrollView.contentOffset.x / scrollView.bounds.size.width;
//    self.pageControl.currentPage = curentPage;
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
