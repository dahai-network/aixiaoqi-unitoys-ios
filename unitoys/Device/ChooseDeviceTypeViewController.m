//
//  ChooseDeviceTypeViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/3/9.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ChooseDeviceTypeViewController.h"
#import "ChooseDeviceTypeTableViewCell.h"
#import "IsBoundingViewController.h"
#import "BlueToothDataManager.h"

@interface ChooseDeviceTypeViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong)IsBoundingViewController *isBoundingVC;

@end

@implementation ChooseDeviceTypeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"绑定";
    self.tableView.tableFooterView = [UIView new];
    // Do any additional setup after loading the view from its nib.
}

//0流量/1通话/2大王卡/3双卡双待
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}

//0流量/1通话/2大王卡/3双卡双待
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"ChooseDeviceTypeTableViewCell";
    ChooseDeviceTypeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell=[[[NSBundle mainBundle] loadNibNamed:@"ChooseDeviceTypeTableViewCell" owner:nil options:nil] firstObject];
    }
    switch (indexPath.row) {
            case 0:
            cell.lbltype.text = @"绑定爱小器手环";
            break;
            case 1:
            cell.lbltype.text = @"绑定钥匙扣";
            break;
        default:
            NSLog(@"绑定啥？");
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
            case 0:
            //爱小器手环
            [BlueToothDataManager shareManager].deviceType = MYDEVICENAMEUNITOYS;
            break;
            case 1:
            //钥匙扣
            [BlueToothDataManager shareManager].deviceType = MYDEVICENAMEUNIBOX;
            break;
        default:
            NSLog(@"什么类型");
            break;
    }
    if (!self.isBoundingVC) {
        self.isBoundingVC = [[IsBoundingViewController alloc] init];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
    [BlueToothDataManager shareManager].isNeedToBoundDevice = YES;
    [self.navigationController pushViewController:self.isBoundingVC animated:YES];
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
