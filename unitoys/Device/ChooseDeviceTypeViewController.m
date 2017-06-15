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
@property (nonatomic, strong)ChooseDeviceTypeTableViewCell *cell;
@property (strong, nonatomic) IBOutlet UIView *headView;

@end

@implementation ChooseDeviceTypeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = INTERNATIONALSTRING(@"选择绑定设备");
    self.tableView.tableHeaderView = self.headView;
    self.tableView.tableFooterView = [UIView new];
    // Do any additional setup after loading the view from its nib.
}

//0流量/1通话/2大王卡/3双卡双待
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    return 185;
}

//0流量/1通话/2大王卡/3双卡双待
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"ChooseDeviceTypeTableViewCell";
    self.cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!self.cell) {
        self.cell=[[[NSBundle mainBundle] loadNibNamed:@"ChooseDeviceTypeTableViewCell" owner:nil options:nil] firstObject];
        self.cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.cell.backGroundButton addTarget:self action:@selector(didClickButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.cell.backGroundButton setBackgroundImage:[UIImage imageNamed:@"image_chooseBound_selected"] forState:UIControlStateHighlighted];
    }
    switch (indexPath.row) {
            case 0:
            self.cell.lbltype.text = INTERNATIONALSTRING(@"爱小器手环");
            self.cell.lblTypeDis.text = INTERNATIONALSTRING(@"请点击搜索爱小器手环进行绑定");
            self.cell.imgType.image = [UIImage imageNamed:@"image_bound_shouhuan"];
            break;
            case 1:
            self.cell.lbltype.text = INTERNATIONALSTRING(@"爱小器双待王");
            self.cell.lblTypeDis.text = INTERNATIONALSTRING(@"请点击搜索爱小器双待王进行绑定");
            self.cell.imgType.image = [UIImage imageNamed:@"image_bound_shuangdaiwang"];
            break;
        default:
            UNDebugLogVerbose(@"绑定啥？");
            break;
    }
    self.cell.backGroundButton.indexPath = indexPath;
    return self.cell;
}

- (void)didClickButton:(CutomButton *)sender {
    if ([BlueToothDataManager shareManager].isOpened) {
        switch (sender.indexPath.row) {
            case 0:
                //爱小器手环
                [BlueToothDataManager shareManager].deviceType = MYDEVICENAMEUNITOYS;
                break;
            case 1:
                //钥匙扣
                [BlueToothDataManager shareManager].deviceType = MYDEVICENAMEUNIBOX;
                break;
            default:
                UNDebugLogVerbose(@"什么类型");
                break;
        }
        if (!self.isBoundingVC) {
            self.isBoundingVC = [[IsBoundingViewController alloc] init];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
        [BlueToothDataManager shareManager].isNeedToBoundDevice = YES;
        [self.navigationController pushViewController:self.isBoundingVC animated:YES];
    } else {
        HUDNormal(INTERNATIONALSTRING(@"请开启蓝牙"))
    }
}

//- (nullable NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    self.cell.imgBackGroundView.image = [UIImage imageNamed:@"image_chooseBound_selected"];
//    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationNone];
//    return indexPath;
//}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    if ([BlueToothDataManager shareManager].isOpened) {
//        switch (indexPath.row) {
//                case 0:
//                //爱小器手环
//                [BlueToothDataManager shareManager].deviceType = MYDEVICENAMEUNITOYS;
//                break;
//                case 1:
//                //钥匙扣
//                [BlueToothDataManager shareManager].deviceType = MYDEVICENAMEUNIBOX;
//                break;
//            default:
//                UNDebugLogVerbose(@"什么类型");
//                break;
//        }
//        if (!self.isBoundingVC) {
//            self.isBoundingVC = [[IsBoundingViewController alloc] init];
//        }
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"scanToConnect" object:@"connect"];
//        [BlueToothDataManager shareManager].isNeedToBoundDevice = YES;
//        [self.navigationController pushViewController:self.isBoundingVC animated:YES];
//    } else {
//        HUDNormal(INTERNATIONALSTRING(@"请开启蓝牙"))
//    }
//}

//- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
//    self.cell.imgBackGroundView.image = [UIImage imageNamed:@"image_chooseBound_unselected"];
//    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationNone];
//}

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
