//
//  HWNewfeatureViewController.m
//  黑马微博2期
//
//  Created by apple on 14-10-10.
//  Copyright (c) 2014年 heima. All rights reserved.
//

#import "HWNewfeatureViewController.h"
//#import "LoginViewController.h"
#import "UNLoginViewController.h"
//#import "UIView+Extension.h"
#import "UIView+Utils.h"
#import "navHomeViewController.h"
#import "DJPageControl.h"
#import <CommonCrypto/CommonDigest.h>
#import "JPUSHService.h"
#define HWNewfeatureCount 4

@interface HWNewfeatureViewController () <UIScrollViewDelegate>
@property (nonatomic, weak) DJPageControl *pageControl;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, assign)int seconds;
@property (nonatomic, strong)NSTimer *timer;
@property (nonatomic, strong)UILabel *timeLabel;
@property (nonatomic, strong)NSMutableDictionary *headers;
@property (nonatomic, assign)BOOL checkToken;

@end

@implementation HWNewfeatureViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // 1.创建一个scrollView：显示所有的新特性图片
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.frame = self.view.bounds;
    scrollView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    // 2.添加图片到scrollView中
    CGFloat scrollW = scrollView.un_width;
    CGFloat scrollH = scrollView.un_height;
    for (int i = 0; i<HWNewfeatureCount; i++) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.un_width = scrollW;
        imageView.un_height = scrollH;
        imageView.un_top = 0;
        imageView.un_left = i * scrollW;
        // 显示图片
        NSString *name = [NSString stringWithFormat:@"%d", i + 1];
        imageView.image = [UIImage imageNamed:name];
        [scrollView addSubview:imageView];
        
        // 如果是最后一个imageView，就往里面添加其他内容
        if (i == HWNewfeatureCount - 1) {
            [self setupLastImageView:imageView];
        }
    }
    
#warning 默认情况下，scrollView一创建出来，它里面可能就存在一些子控件了
#warning 就算不主动添加子控件到scrollView中，scrollView内部还是可能会有一些子控件
    
    // 3.设置scrollView的其他属性
    // 如果想要某个方向上不能滚动，那么这个方向对应的尺寸数值传0即可
    scrollView.contentSize = CGSizeMake(HWNewfeatureCount * scrollW, 0);
    scrollView.bounces = NO; // 去除弹簧效果
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.delegate = self;
    
    // 4.添加pageControl：分页，展示目前看的是第几页
    DJPageControl *pageControl = [[DJPageControl alloc] init];
    pageControl.numberOfPages = HWNewfeatureCount;
    pageControl.backgroundColor = [UIColor redColor];
    pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    pageControl.pageIndicatorTintColor = [UIColor whiteColor];
    pageControl.un_centerX = scrollW * 0.5;
    pageControl.un_centerY = scrollH - 50;
    [self.view addSubview:pageControl];
    self.pageControl = pageControl;
    
    // UIPageControl就算没有设置尺寸，里面的内容还是照常显示的
    //    pageControl.width = 100;
    //    pageControl.height = 50;
    //    pageControl.userInteractionEnabled = NO;
    
//    UITextField *text = [[UITextField alloc] init];
//    text.frame = CGRectMake(10, 20, 100, 50);
//    text.borderStyle = UITextBorderStyleRoundedRect;
//    [self.view addSubview:text];
}

//- (void)changeColor:(UIPageControl *)pageControl {
//    switch (pageControl.currentPage) {
//        case 0:
//            pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0.490 green:0.725 blue:0.604 alpha:1.000];
//            pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.863 green:0.859 blue:0.863 alpha:1.000];
//            break;
//        case 1:
//            pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0.235 green:0.627 blue:0.835 alpha:1.000];
//            pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.863 green:0.859 blue:0.863 alpha:1.000];
//            break;
//        case 2:
//            pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0.839 green:0.333 blue:0.329 alpha:1.000];
//            pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.863 green:0.859 blue:0.863 alpha:1.000];
//            break;
//        case 3:
//            pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0.871 green:0.451 blue:0.306 alpha:1.000];
//            pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.863 green:0.859 blue:0.863 alpha:1.000];
//            break;
//            
//        default:
//            break;
//    }
//}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    double page = scrollView.contentOffset.x / scrollView.un_width;
    // 四舍五入计算出页码
    self.pageControl.currentPage = (int)(page + 0.5);
//    [self changeColor:self.pageControl];
    // 1.3四舍五入 1.3 + 0.5 = 1.8 强转为整数(int)1.8= 1
    // 1.5四舍五入 1.5 + 0.5 = 2.0 强转为整数(int)2.0= 2
    // 1.6四舍五入 1.6 + 0.5 = 2.1 强转为整数(int)2.1= 2
    // 0.7四舍五入 0.7 + 0.5 = 1.2 强转为整数(int)1.2= 1
}

/**
 *  初始化其他的imageView
 *
 *  @param imageView
 */
//- (void)setUpOtherImageView:(UIImageView *)imageView {
//    // 开启交互功能
//    imageView.userInteractionEnabled = YES;
//    //跳过按钮
//    UIButton *jumpBtn = [[UIButton alloc] init];
//    jumpBtn.size = CGSizeMake(imageView.width * 0.14497, imageView.height * 0.04078);
//    jumpBtn.centerX = imageView.width * 0.87;
//    jumpBtn.centerY = imageView.height * 0.035;
//    [jumpBtn setTitle:@"" forState:UIControlStateNormal];
//    [jumpBtn addTarget:self action:@selector(startClick) forControlEvents:UIControlEventTouchUpInside];
////    jumpBtn.backgroundColor = [UIColor colorWithRed:0.000 green:1.000 blue:0.000 alpha:0.297];
//    [imageView addSubview:jumpBtn];
//}

/**
 *  初始化最后一个imageView
 *
 *  @param imageView 最后一个imageView
 */
- (void)setupLastImageView:(UIImageView *)imageView
{
    // 开启交互功能
    imageView.userInteractionEnabled = YES;
    
    // 1.分享给大家（checkbox）
    
//    UIButton *shareBtn = [[UIButton alloc] init];
//    [shareBtn setImage:[UIImage imageNamed:@"new_feature_share_false"] forState:UIControlStateNormal];
//    [shareBtn setImage:[UIImage imageNamed:@"new_feature_share_true"] forState:UIControlStateSelected];
//    [shareBtn setTitle:@"分享给大家" forState:UIControlStateNormal];
//    [shareBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    shareBtn.titleLabel.font = [UIFont systemFontOfSize:15];
//    shareBtn.width = 200;
//    shareBtn.height = 30;
//    shareBtn.centerX = imageView.width * 0.5;
//    shareBtn.centerY = imageView.height * 0.65;
//    [shareBtn addTarget:self action:@selector(shareClick:) forControlEvents:UIControlEventTouchUpInside];
//    [imageView addSubview:shareBtn];
//    shareBtn.backgroundColor = [UIColor redColor];
//    shareBtn.imageView.backgroundColor = [UIColor blueColor];
//    shareBtn.titleLabel.backgroundColor = [UIColor yellowColor];
    
    // top left bottom right
    
    // EdgeInsets: 自切
    // contentEdgeInsets:会影响按钮内部的所有内容（里面的imageView和titleLabel）
    //    shareBtn.contentEdgeInsets = UIEdgeInsetsMake(10, 100, 0, 0);
    
    // titleEdgeInsets:只影响按钮内部的titleLabel
//    shareBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    
    // imageEdgeInsets:只影响按钮内部的imageView
//    shareBtn.imageEdgeInsets = UIEdgeInsetsMake(20, 0, 0, 50);
    
    
    
//    shareBtn.titleEdgeInsets
//    shareBtn.imageEdgeInsets
//    shareBtn.contentEdgeInsets
    
    // 2.开始
    UIButton *startBtn = [[UIButton alloc] init];
    [startBtn setBackgroundImage:[UIImage imageNamed:@"button_start_unselected"] forState:UIControlStateNormal];
    [startBtn setBackgroundImage:[UIImage imageNamed:@"button_start_selected"] forState:UIControlStateHighlighted];
//    startBtn.size = startBtn.currentBackgroundImage.size;
    startBtn.un_size = CGSizeMake(157, 48);
    startBtn.un_centerX = imageView.un_width * 0.5;
    startBtn.un_centerY = imageView.un_height - 105;
    [startBtn setTitle:@"" forState:UIControlStateNormal];
    [startBtn addTarget:self action:@selector(startClick) forControlEvents:UIControlEventTouchUpInside];
//    startBtn.backgroundColor = [UIColor colorWithRed:0.000 green:1.000 blue:0.000 alpha:0.297];
    [imageView addSubview:startBtn];
    
    //加入倒计时
    self.seconds = 3;
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageView.un_width - 55, 10, 50, 30)];
    self.timeLabel.text = [NSString stringWithFormat:@"%d秒", self.seconds];
    self.timeLabel.textColor = [UIColor colorWithRed:1.000 green:0.384 blue:0.000 alpha:1.000];
//    self.timeLabel.backgroundColor = [UIColor colorWithRed:1.000 green:0.296 blue:0.000 alpha:0.455];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    [imageView addSubview:self.timeLabel];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.pageControl.currentPage == HWNewfeatureCount - 1) {
        //加入倒计时
        self.seconds = 3;
        self.timeLabel.text = [NSString stringWithFormat:@"%d秒", self.seconds];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerLessAction) userInfo:nil repeats:YES];
    } else {
        [self.timer setFireDate:[NSDate distantFuture]];
        self.timeLabel.text = @"3秒";
    }
}

- (void)timerLessAction {
    self.seconds--;
    self.timeLabel.text = [NSString stringWithFormat:@"%d秒", self.seconds];
//    NSLog(@"读秒 -- %d", self.seconds);
    if (self.seconds == 0) {
        [self startClick];
    }
}

- (void)shareClick:(UIButton *)shareBtn
{
    // 状态取反
    shareBtn.selected = !shareBtn.isSelected;
}

- (void)startClick
{
    [self.timer setFireDate:[NSDate distantFuture]];
    [self checkLogin];
}

- (void)checkLogin {
//    NSString *strGetLogin = [apiGetLogin stringByAppendingString:[self getParamStr]];
    
    NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    if (userdata) {
//        strGetLogin = [NSString stringWithFormat:@"%@&TOKEN=%@",strGetLogin,[userdata objectForKey:@"Token"]];
        //
    }else{
        [self loadLoginViewController];
    }
    //    HUDNoStop1(@"正在登录...")
    self.checkToken = YES;
    [self getBasicHeader];
    [SSNetworkRequest getRequest:apiGetLogin params:nil success:^(id resonseObj){
        
        if (resonseObj) {
            if ([[resonseObj objectForKey:@"status"] intValue]==1) {
                //                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userdata[@"Tel"]];
                //更新别名为token
                NSString *alias = [NSString stringWithFormat:@"aixiaoqi%@", userdata[@"Token"]];
                [JPUSHService setTags:nil alias:alias fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
                    NSLog(@"极光别名：irescode = %d\n itags = %@\n ialias = %@", iResCode, iTags, iAlias);
                }];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"loginSuccessAndCreatTcpNotif" object:@"loginSuccessAndCreatTcpNotif"];
                //                    NSLog(@"拿到数据：%@",resonseObj);
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                if (storyboard) {
                    UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                    if (mainViewController) {
                        UIWindow *window = [UIApplication sharedApplication].keyWindow;
                        window.rootViewController = mainViewController;
                    }
                }
                
                //                [[UITabBar appearance] setBackgroundImage:<#(UIImage * _Nullable)#>:[UIColor blueColor]];
            }else{
                [self loadLoginViewController];
                //                [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"999" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            }
        }else{
            [self loadLoginViewController];
            //            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"服务器好像有点忙，请稍后重试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        }
        
    }failure:^(id dataObj, NSError *error) {
        NSLog(@"登录失败：%@",[error description]);
        //        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable) {
        //
        //        }
        
        //        [self loadLoginViewController];
        
        HUDNormal(INTERNATIONALSTRING(@"网络貌似有问题"))
        NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
        if (userdata) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            if (storyboard) {
                UIViewController *mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
                if (mainViewController) {
                    UIWindow *window = [UIApplication sharedApplication].keyWindow;
                    window.rootViewController = mainViewController;
                }
            }
        }
    } headers:self.headers];
}

- (void)loadLoginViewController {
    //    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    //    if (storyboard) {
    //        UIViewController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];
    //        if (loginViewController) {
    //            UIWindow *window = [UIApplication sharedApplication].keyWindow;
    //            window.rootViewController = loginViewController;
    //        }
    //    }
    UNLoginViewController *loginVc = [[UNLoginViewController alloc] init];
    if (loginVc) {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        window.rootViewController = loginVc;
    }
}

-(void)getBasicHeader
{
    //进行Header的构造，partner，Expries，Sign，TOKEN
    self.headers = [[NSMutableDictionary alloc] init];
    [self.headers setObject:@"2006808" forKey:@"partner"];
    
    //    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    //    NSInteger a=[dat timeIntervalSince1970];
    //    NSString *timestemp = [NSString stringWithFormat:@"%ld", (long)a];
    NSString *timestemp = @"1471316792";
    
    [self.headers setObject:timestemp forKey:@"expires"];
    
    timestemp = [NSString stringWithFormat:@"2006808%@BAS123!@#FD1A56K",timestemp];
    
    [self.headers setObject:[self md5:timestemp] forKey:@"sign"];
    if (self.checkToken) {
        NSDictionary *userdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
        if (userdata) {
            [self.headers setObject:[userdata objectForKey:@"Token"] forKey:@"TOKEN"];
        }
    }
    
}

- (NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (BOOL)prefersStatusBarHidden{
    return YES; // 返回NO表示要显示，返回YES将hiden
}

/*
 1.程序启动会自动加载叫做Default的图片
 1> 3.5inch 非retain屏幕：Default.png
 2> 3.5inch retina屏幕：Default@2x.png
 3> 4.0inch retain屏幕: Default-568h@2x.png

 2.只有程序启动时自动去加载的图片, 才会自动在4inch retina时查找-568h@2x.png
 */

/*
 一个控件用肉眼看不见，有哪些可能
 1.根本没有创建实例化这个控件
 2.没有设置尺寸
 3.控件的颜色跟父控件的背景色一样（实际上已经显示了，只不过用肉眼看不见）
 4.透明度alpha <= 0.01
 5.hidden = YES
 6.没有添加到父控件中
 7.被其他控件挡住了
 8.位置不对
 9.父控件发生了以上情况
 10.特殊情况
 * UIImageView没有设置image属性，或者设置的图片名不对
 * UILabel没有设置文字，或者文字颜色和跟父控件的背景色一样
 * UITextField没有设置文字，或者没有设置边框样式borderStyle
 * UIPageControl没有设置总页数，不会显示小圆点
 * UIButton内部imageView和titleLabel的frame被篡改了，或者imageView和titleLabel没有内容
 * .....
 
 添加一个控件的建议（调试技巧）：
 1.最好设置背景色和尺寸
 2.控件的颜色尽量不要跟父控件的背景色一样
 */
@end
