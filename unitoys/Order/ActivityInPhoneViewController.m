//
//  ActivityInPhoneViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/7/8.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ActivityInPhoneViewController.h"

@interface ActivityInPhoneViewController ()

@end

@implementation ActivityInPhoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)dismissToBackView:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)goToSystemSetView:(UIButton *)sender {
    if (kSystemVersionValue >= 8.0) {
        if (kSystemVersionValue >= 10.0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=Phone"] options:@{}     completionHandler:nil];
        }else{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=Phone"]];
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
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
