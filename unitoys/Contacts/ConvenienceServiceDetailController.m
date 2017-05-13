//
//  ConvenienceServiceDetailController.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/10.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ConvenienceServiceDetailController.h"
#import "OpenConvenienceServiceController.h"
#import "UNDatabaseTools.h"

@interface ConvenienceServiceDetailController ()
@property (nonatomic, copy) NSDictionary *communicateDetailInfo;
@end

@implementation ConvenienceServiceDetailController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"省心服务";
    self.phoneNumLabel.text = self.currentPhoneNum;
    [self checkCommunicateDetailById];
}

- (void)initData
{
    
}

- (void)checkCommunicateDetailById {
    HUDNoStop1(INTERNATIONALSTRING(@"正在加载..."))
    self.checkToken = YES;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:self.packageId,@"id", nil];
    NSString *apiNameStr = [NSString stringWithFormat:@"%@id%@", @"apiPackageByID", [self.packageId stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    [self getBasicHeader];
    [SSNetworkRequest getRequest:apiPackageByID params:params success:^(id responseObj) {
        if ([[responseObj objectForKey:@"status"] intValue]==1) {
            [[UNDatabaseTools sharedFMDBTools] insertDataWithAPIName:apiNameStr dictData:responseObj];
            self.communicateDetailInfo = responseObj[@"data"][@"list"];
            NSLog(@"%@", self.communicateDetailInfo);
            [self reloadData];
        }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
        }else{
            //数据请求失败
            HUDNormal(responseObj[@"msg"])
        }
    } failure:^(id dataObj, NSError *error) {
        NSDictionary *responseObj = [[UNDatabaseTools sharedFMDBTools] getResponseWithAPIName:apiNameStr];
        if (responseObj) {
            self.communicateDetailInfo = responseObj[@"data"][@"list"];
            [self reloadData];
        }
        NSLog(@"啥都没：%@",[error description]);
    } headers:self.headers];
}

- (void)reloadData
{
    [self.bannerImageView sd_setImageWithURL:[NSURL URLWithString:self.communicateDetailInfo[@"DescTitlePic"]] placeholderImage:nil];
    [self.detailImageView sd_setImageWithURL:[NSURL URLWithString:self.communicateDetailInfo[@"DescPic"]] placeholderImage:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)openService:(UIButton *)sender {
    sender.enabled = NO;
    NSLog(@"开通");
    OpenConvenienceServiceController *openServiceVc = [[OpenConvenienceServiceController alloc] init];
    openServiceVc.packageID = self.packageId;
    openServiceVc.packageDict = self.communicateDetailInfo;
    [self.navigationController pushViewController:openServiceVc animated:YES];
    sender.enabled = YES;
}


@end
