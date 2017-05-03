//
//  StatuesViewDetailViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/4/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "StatuesViewDetailViewController.h"
#import "BlueToothDataManager.h"

@interface StatuesViewDetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@end

@implementation StatuesViewDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"详情";
    [self setupLabelTextWithStr:[BlueToothDataManager shareManager].statuesTitleString];
    // Do any additional setup after loading the view from its nib.
}

- (void)setupLabelTextWithStr:(NSString *)statueString {
    if ([statueString isEqualToString:HOMESTATUETITLE_NETWORKCANNOTUSE]) {
        self.detailLabel.text = @"当前网络不可用，请检查你的网络设置。";
    } else if ([statueString isEqualToString:HOMESTATUETITLE_NOTBOUND]) {
        self.detailLabel.text = @"请先绑定爱小器智能通讯硬件。";
    } else if ([statueString isEqualToString:HOMESTATUETITLE_NOTCONNECTED]) {
        self.detailLabel.text = @"未连上爱小器智能通讯硬件，请检查周围的设备是否有电。";
    } else if ([statueString isEqualToString:HOMESTATUETITLE_NOTINSERTCARD]) {
        self.detailLabel.text = @"爱小器智能通讯硬件设备中未插入电话卡，或插入的卡无效。";
    } else if ([statueString isEqualToString:HOMESTATUETITLE_REGISTING]) {
        self.detailLabel.text = @"电话卡正在连接运营商，请稍后。";
    } else {
        self.detailLabel.text = statueString;
    }
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
