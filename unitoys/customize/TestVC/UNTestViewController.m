//
//  UNTestViewController.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNTestViewController.h"
#import "global.h"
#import "UNPresentTool.h"
#import "UNPopTipMsgView.h"
#import "UNReadyActivateController.h"
#import "UNMessageContentController.h"
#import "HLLoadingView.h"
#import "LookLogController.h"
#import "UNTestTableViewController.h"

#import "UNAnimateController.h"
#import "MBProgressHUD+UNTip.h"

@interface UNTestViewController ()
@property (nonatomic, strong) UNPresentTool *presentTool;
@property (nonatomic, weak) UNPopTipMsgView *popView;

@property (nonatomic, strong) HLLoadingView *loadingView;
@end

@implementation UNTestViewController

- (HLLoadingView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [[HLLoadingView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        [_loadingView setLineWidth:3.0];
        _loadingView.un_centerX = self.view.un_width * 0.5;
        _loadingView.un_centerY = self.view.un_height * 0.5;
        [self.view addSubview:_loadingView];
    }
    return _loadingView;
}
- (IBAction)buttonArrayAction:(UIButton *)sender {
    switch (sender.tag) {
        case 1:
        {
            //present动画
            [self initPopView];
        }
            break;
        case 2:
        {
            //手机激活引导
            [self pushActive];
            
        }
            break;
        case 3:
        {
            //短信界面
//            [self pushMessageVc];
            //上传日志
            [self pushLogVC];
        }
            break;
        case 4:
        {
            //动画
            [self startLoadingAnima];
        }
            break;
        case 5:
        {
            [self testTableViewVC];
        }
            break;
        case 6:
        {
            [self pushAnimate];
        }
            break;
        case 7:
        {
            [self startMBProgressAnimate];
        }
            break;
        case 8:
        {
            
        }
            break;
        default:
            break;
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.view.backgroundColor = [UIColor whiteColor];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Present" style:UIBarButtonItemStyleDone target:self action:@selector(presentVc)];
}

- (void)startMBProgressAnimate
{
    [MBProgressHUD showLoadingWithMessage:@"正在加载"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD showLoadingWithProgress:0.5 ProgressType:UNProgressTypeDeterminateHorizontalBar];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD showSuccess:@"成功"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD showMessage:@"请稍等..."];
            });
        });
    });
}

//引导激活
- (void)pushActive
{
    UNReadyActivateController *activeVc = [[UNReadyActivateController alloc] init];
    activeVc.defaultDay = @"1";
    [self.navigationController pushViewController:activeVc animated:YES];
}

//短信
- (void)pushMessageVc
{
    UNMessageContentController *messageContentVc = [[UNMessageContentController alloc] init];
    messageContentVc.toTelephone = @"10086";
    messageContentVc.toPhoneName = @"10086";
    //    messageContentVc.isNewMessage = YES;
    [self.navigationController pushViewController:messageContentVc animated:YES];
}

- (void)pushLogVC
{
    LookLogController *logVc = [[LookLogController alloc] init];
    [self.navigationController pushViewController:logVc animated:YES];
}

- (void)pushAnimate
{
    UNAnimateController *animateVc = [[UNAnimateController alloc] init];
    [self.navigationController pushViewController:animateVc animated:YES];
}

- (void)startLoadingAnima
{
    [self.loadingView startAnimating];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.loadingView stopAnimating];
    });
}

- (void)testTableViewVC
{
    UNTestTableViewController *tableVc = [[UNTestTableViewController alloc] initWithUrl:apiSMSLast andParams:@{@"pageNumber" : @"1", @"pageSize" : @"10"}];
    
    [self.navigationController pushViewController:tableVc animated:YES];
}

- (void)initPopView
{
    if (!_presentTool) {
        _presentTool = [UNPresentTool new];
    }
    if (_popView) {
        return;
    }
    UNPopTipMsgView *view = [UNPopTipMsgView sharePopTipMsgViewTitle:@"提示" detailTitle:@"有新的流量套餐出现了,是否去看看"];
    _popView = view;
    view.leftButtonText = @"下次再去";
    view.rightButtonText = @"去看看";
    kWeakSelf
    view.popTipButtonAction = ^(NSInteger type) {
        [weakSelf.presentTool dismissDuration:0.5 completion:^{
            if (type == 2) {
                NSLog(@"push新界面");
            }
            weakSelf.presentTool = nil;
        }];
    };
    view.topOffset = 64;
    [_presentTool presentContentView:view duration:0.85 inView:nil];
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
