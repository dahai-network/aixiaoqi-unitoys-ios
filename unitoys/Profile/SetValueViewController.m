//
//  SetValueViewController.m
//  unitoys
//
//  Created by sumars on 16/11/4.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "SetValueViewController.h"
#import "UNNetworkManager.h"
#import "MBProgressHUD+UNTip.h"

@interface SetValueViewController ()

@end

@implementation SetValueViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edtValue.text = self.name;
    
    //左边按钮
//    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:INTERNATIONALSTRING(@"取消") style:UIBarButtonItemStyleDone target:self action:@selector(leftButtonAction)];
//    self.navigationItem.leftBarButtonItem = left;
    
//    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:INTERNATIONALSTRING(@"保存") style:UIBarButtonItemStyleDone target:self action:@selector(rightButtonAction)];
//    self.navigationItem.rightBarButtonItem = right;
    [self setRightButton:INTERNATIONALSTRING(@"保存")];
    
//    NSMutableDictionary *textAttrs = [NSMutableDictionary dictionary];
//    textAttrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
//    textAttrs[NSFontAttributeName] = [UIFont systemFontOfSize:14];
//    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
//    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
    // Do any additional setup after loading the view.
}

//- (void)leftButtonAction {
//    [self.navigationController popViewControllerAnimated:YES];
//}

//- (void)rightButtonAction {
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"setValue" object:self.edtValue.text];
//}

- (void)rightButtonClick {
    [self changeNickName];
}

- (void)changeNickName {
    [MBProgressHUD showLoadingWithMessage:@"正在保存..."];
    [UNNetworkManager postUrl:apiUpdateUserInfo parameters:@{@"NickName" : self.edtValue.text} success:^(ResponseType type, id  _Nullable responseObj) {
        if (type == ResponseTypeSuccess) {
            [MBProgressHUD showSuccess:responseObj[@"msg"]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setValue" object:self.edtValue.text];
            [self.navigationController popViewControllerAnimated:YES];
        }else if (type == ResponseTypeFailed){
            [MBProgressHUD showError:responseObj[@"msg"]];
        }
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD showError:@"网络请求失败"];
    }];
    
//    self.checkToken = YES;
//    NSDictionary *dict = @{@"NickName" : self.edtValue.text};
//    
//    [self getBasicHeader];
//    [SSNetworkRequest postRequest:apiUpdateUserInfo params:dict success:^(id responseObj) {
//        if ([[responseObj objectForKey:@"status"] intValue]==1) {
//            
//            NSLog(@"查询到的用户数据：%@",responseObj);
//            
//            //            [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
//            HUDNormal(responseObj[@"msg"])
//            
//        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
//            
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
//        }else{
//            //数据请求失败
//        }
//        
//        [self.navigationController popViewControllerAnimated:YES];
//        
//    } failure:^(id dataObj, NSError *error) {
//        //
//        NSLog(@"啥都没：%@",[error description]);
//    } headers:self.headers];
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
