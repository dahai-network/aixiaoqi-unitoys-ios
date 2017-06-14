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

@interface UNTestViewController ()
@property (nonatomic, strong) UNPresentTool *presentTool;
@property (nonatomic, weak) UNPopTipMsgView *popView;
@end

@implementation UNTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = DefultColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Present" style:UIBarButtonItemStyleDone target:self action:@selector(presentVc)];
}

- (void)presentVc
{
    //present动画
//    [self initPopView];
    
    //手机激活引导
//    [self pushActive];
    
    //短信界面
//    [self pushMessageVc];
    
    //上传日志
    [self updateLogAction];
    
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

- (void)updateLogAction
{
    [[UNDDLogManager sharedInstance] updateLogToServerWithLogCount:2];
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
