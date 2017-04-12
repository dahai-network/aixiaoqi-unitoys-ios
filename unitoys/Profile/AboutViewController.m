//
//  AboutViewController.m
//  unitoys
//
//  Created by sumars on 16/9/20.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "AboutViewController.h"
#import "UIImageView+WebCache.h"
#import "BindDeviceViewController.h"
//#import "AlarmListViewController.h"
#import "BlueToothDataManager.h"
#import "ChooseDeviceTypeViewController.h"
#import "WristbandSettingViewController.h"
#import "PurviewSettingViewController.h"

#define CELLHEIGHT 44

@interface AboutViewController ()
@property (nonatomic, strong) ChooseDeviceTypeViewController *chooseDeviceTypeVC;

@end

@implementation AboutViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = nil;
//    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //消除导航栏横线
    //自定义一个NaVIgationBar
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    //消除阴影
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(needRefreshAmount) name:@"NeedRefreshAmount" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryAmount) name:@"NeedRefreshInfo" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chargeConfrim) name:@"ChargeConfrim" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeDeviceStatue) name:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeDeviceStatue) name:@"boundSuccess" object:@"boundSuccess"];
}

- (void)changeDeviceStatue {
    [self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self queryAmount];
}

- (void)chargeConfrim {
    [self.navigationController popToRootViewControllerAnimated:YES];
}


- (void)amountDetail {
    //显示详情
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    if (storyboard) {
        self.tabBarController.tabBar.hidden = YES;
        UIViewController *amountDetailViewController = [storyboard instantiateViewControllerWithIdentifier:@"amountDetailViewController"];
        if (amountDetailViewController) {
            [self.navigationController pushViewController:amountDetailViewController animated:YES];
        }
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    self.tabBarController.tabBar.hidden = NO;
}


- (void)needRefreshAmount {
    self.checkToken = YES;
    
    [self getBasicHeader];
    //    NSLog(@"表演头：%@",self.headers);
    [SSNetworkRequest getRequest:apiGetUserAmount params:nil success:^(id responseObj) {
        //
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            self.lblAmount.text = [[[responseObj objectForKey:@"data"] objectForKey:@"amount"] stringValue];
            float amount = [responseObj[@"data"][@"amount"] floatValue];
            self.lblAmount.text = [NSString stringWithFormat:@"余额：%.2f元", amount];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
        }
        
        //        NSLog(@"查询到的用户数据：%@",responseObj);
    } failure:^(id dataObj, NSError *error) {
        //
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}



- (void)queryAmount {
    NSDictionary *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"userData"];
    
    self.lblNickName.text = [userData objectForKey:@"NickName"];
    self.lblPhoneNumber.text = [userData objectForKey:@"Tel"];
    
    //    NSString *imageUrl = [NSString stringWithFormat:@"http://manage.ali168.com%@",[userData objectForKey:@"UserHead"]];\\
    
    NSString *imageUrl = [userData objectForKey:@"UserHead"];
    
    NSLog(@"头像头像:%@",imageUrl);
    
//    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
    
    
    
    [self.ivUserHead sd_setImageWithURL:[NSURL URLWithString:imageUrl]];
    
    
    [self.ivUserHead.layer setMasksToBounds:YES];
  
    [self.ivUserHead.layer setCornerRadius:self.ivUserHead.bounds.size.width/2];
    self.ivUserHead.layer.borderColor = [UIColor whiteColor].CGColor;
    self.ivUserHead.layer.borderWidth = 2;
    
//    self.ivUserHead.image = [UIImage imageWithData:imageData];

    
//    [self.ivUserHead drawRect:self.ivUserHead.frame];
    
    [self needRefreshAmount];
}

#pragma mark ---TableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 2) {
                [self amountDetail];
            }
            break;
        case 1:
            HUDNormal(@"激活套餐")
            break;
        case 2:
            //跳转到设备界面
            if ([BlueToothDataManager shareManager].isBounded) {
                //有绑定
                UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
                BindDeviceViewController *bindDeviceViewController = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
                if (bindDeviceViewController) {
                    self.tabBarController.tabBar.hidden = YES;
                    bindDeviceViewController.hintStrFirst = [BlueToothDataManager shareManager].statuesTitleString;
                    [self.navigationController pushViewController:bindDeviceViewController animated:YES];
                }
            } else {
                //没绑定
                if (!self.chooseDeviceTypeVC) {
                    self.chooseDeviceTypeVC = [[ChooseDeviceTypeViewController alloc] init];
                }
                [self.navigationController pushViewController:self.chooseDeviceTypeVC animated:YES];
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0:
                {
                    PurviewSettingViewController *purviewSettingVC = [[PurviewSettingViewController alloc] init];
                    [self.navigationController pushViewController:purviewSettingVC animated:YES];
                }
                    break;
                case 1:
                {
                    //开始调用设置
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Setting" bundle:nil];
                    if (storyboard) {
                        self.tabBarController.tabBar.hidden = YES;
                        UIViewController *settingViewController = [storyboard instantiateViewControllerWithIdentifier:@"settingViewController"];
                        if (settingViewController) {
                            [self.navigationController pushViewController:settingViewController animated:YES];
                        }
                    }
                }
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section{
    view.tintColor = UIColorFromRGB(0xf5f5f5);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 3) {
        return 10;
    } else {
        return 5;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

#pragma mark -- Table
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return 3;
            break;
        case 1:
            return 1;
            break;
        case 2:
            return 1;
            break;
        case 3:
            return 2;
            break;
            
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    return 171;
                    break;
                case 1:
                    return 55;
                    break;
                case 2:
                    return 55;
                    break;
                default:
                    return 55;
                    break;
            }
            break;
        case 1:
            return 120;
            break;
        case 2:
            return 120;
            break;
        case 3:
            return 55;
            break;
        default:
            return 55;
            break;
    }
}

- (IBAction)accountRecharge:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    if (storyboard) {
        self.tabBarController.tabBar.hidden = YES;
        UIViewController *rechargeViewController = [storyboard instantiateViewControllerWithIdentifier:@"rechargeViewController"];
        if (rechargeViewController) {
            [self.navigationController pushViewController:rechargeViewController animated:YES];
        }
    }
}

- (IBAction)editProfile:(id)sender {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    if (storyboard) {
        self.tabBarController.tabBar.hidden = YES;
        UIViewController *profileViewController = [storyboard instantiateViewControllerWithIdentifier:@"profileViewController"];
        if (profileViewController) {
            [self.navigationController pushViewController:profileViewController animated:YES];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NeedRefreshAmount" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NeedRefreshInfo" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ChargeConfrim" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"deviceIsDisconnect" object:@"deviceIsDisconnect"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"boundSuccess" object:@"boundSuccess"];
}
@end
