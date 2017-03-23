//
//  AboutViewController.m
//  unitoys
//
//  Created by sumars on 16/9/20.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "AboutViewController.h"
#import "UIimageView+WebCache.h"
#import "BindDeviceViewController.h"
//#import "AlarmListViewController.h"
#import "BlueToothDataManager.h"
#import "ChooseDeviceTypeViewController.h"
#import "WristbandSettingViewController.h"

#define CELLHEIGHT 44

@interface AboutViewController ()
@property (nonatomic, strong) ChooseDeviceTypeViewController *chooseDeviceTypeVC;

@end

@implementation AboutViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = nil;
//    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UITapGestureRecognizer *amountTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(amountDetail)];
    
    [self.vwAmount addGestureRecognizer:amountTap];
    
    UITapGestureRecognizer *backgroundTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editProfile:)];
    
    [self.ivBackground addGestureRecognizer:backgroundTap];
    
    
    
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
            self.lblAmount.text = [NSString stringWithFormat:@"￥%.2f", amount];
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
    
//    self.ivUserHead.image = [UIImage imageWithData:imageData];

    
//    [self.ivUserHead drawRect:self.ivUserHead.frame];
    
    [self needRefreshAmount];
}

#pragma mark ---TableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"当前选择：%ld",(long)indexPath.row);
    if (indexPath.section==1) {
        if (indexPath.row==0) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Order" bundle:nil];
            if (storyboard) {
                self.tabBarController.tabBar.hidden = YES;
                UIViewController *orderListViewController = [storyboard instantiateViewControllerWithIdentifier:@"orderListViewController"];
                if (orderListViewController) {
                    [self.navigationController pushViewController:orderListViewController animated:YES];
                }
            }
        }
        if (indexPath.row == 1) {
            //跳转到设备界面
//            UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
//            
//            BindDeviceViewController *bindDeviceViewController = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
//            if (bindDeviceViewController) {
//                self.tabBarController.tabBar.hidden = YES;
//                [self.navigationController pushViewController:bindDeviceViewController animated:YES];
//            }
            if ([BlueToothDataManager shareManager].isBounded) {
                //有绑定
                UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Device" bundle:nil];
                BindDeviceViewController *bindDeviceViewController = [mainStory instantiateViewControllerWithIdentifier:@"bindDeviceViewController"];
                if (bindDeviceViewController) {
                    self.tabBarController.tabBar.hidden = YES;
//                    bindDeviceViewController.hintStrFirst = self.leftButton.titleLabel.text;
                    [self.navigationController pushViewController:bindDeviceViewController animated:YES];
                }
            } else {
                //没绑定
                if (!self.chooseDeviceTypeVC) {
                    self.chooseDeviceTypeVC = [[ChooseDeviceTypeViewController alloc] init];
                }
                [self.navigationController pushViewController:self.chooseDeviceTypeVC animated:YES];
            }
        }
    }
    if (indexPath.section == 2) {
//        HUDNormal(@"手环设置")
        WristbandSettingViewController *wristbandSettingVC = [[WristbandSettingViewController alloc] init];
        [self.navigationController pushViewController:wristbandSettingVC animated:YES];
//        AlarmListViewController *alarmListVC;
//        switch (indexPath.row) {
//            case 0:
//                //来电提醒
//                HUDNormal(INTERNATIONALSTRING(@"来电提醒"))
//                break;
//            case 1:
//                //手环闹钟
////                HUDNormal(@"手环闹钟")
//                alarmListVC = [[AlarmListViewController alloc] init];
//                [self.navigationController pushViewController:alarmListVC animated:YES];
//                break;
//            case 2:
//                //短信提醒
//                HUDNormal(INTERNATIONALSTRING(@"短信提醒"))
//                break;
//            case 3:
//                //微信消息提醒
//                HUDNormal(INTERNATIONALSTRING(@"微信消息提醒"))
//                break;
//            case 4:
//                //QQ消息提醒
//                HUDNormal(INTERNATIONALSTRING(@"QQ消息提醒"))
//                break;
//            default:
//                break;
//        }
    }
    if (indexPath.section==3) {
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
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section{
    view.tintColor = [UIColor colorWithRed:234/255.0 green:236/255.0 blue:240/255.0 alpha:1];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    //有闹钟时注销此方法
//    if (section == 3 || section == 2) {
//        return 0.01;
//    } else {
//        return 10;
//    }
    if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
        //有闹钟时打开此方法
        if (section == 3) {
            return 0.01;
        } else {
            return 10;
        }
    } else {
        if (section == 2 || section == 3) {
            return 0.01;
        } else {
            return 10;
        }
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
            return 1;
            break;
        case 1:
            return 2; //如果没有内容有可能只能显示一行并提示用户购买，如果有还得算出有多少已购
            break;
        case 2:
            return 1;
            break;
        case 3:
            return 1;
            break;
            
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==0) {
        return 172*[UIScreen mainScreen].bounds.size.width/320;
    } else if(indexPath.section==1){
        
            return CELLHEIGHT*[UIScreen mainScreen].bounds.size.width/320;
        
    }else if(indexPath.section==2){
        //有闹钟时打开此行
        if ([[BlueToothDataManager shareManager].connectedDeviceName isEqualToString:MYDEVICENAMEUNITOYS]) {
            return CELLHEIGHT*[UIScreen mainScreen].bounds.size.width/320;
        } else {
            //有闹钟时注销此行
            return 0;
        }
    }else if(indexPath.section==3){
        
        return CELLHEIGHT*[UIScreen mainScreen].bounds.size.width/320;
        
    }else return 0;
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
