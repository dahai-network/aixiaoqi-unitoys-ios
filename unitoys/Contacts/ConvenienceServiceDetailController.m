//
//  ConvenienceServiceDetailController.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ConvenienceServiceDetailController.h"
#import "OpenConvenienceServiceController.h"

@interface ConvenienceServiceDetailController ()

@end

@implementation ConvenienceServiceDetailController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"省心服务";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)openService:(UIButton *)sender {
    sender.enabled = NO;
    NSLog(@"开通");
    OpenConvenienceServiceController *openServiceVc = [[OpenConvenienceServiceController alloc] init];
    [self.navigationController pushViewController:openServiceVc animated:YES];
    sender.enabled = YES;
}


@end
