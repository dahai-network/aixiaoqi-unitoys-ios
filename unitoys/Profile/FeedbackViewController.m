//
//  FeedbackViewController.m
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "FeedbackViewController.h"

@implementation FeedbackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.contentFeedback.placeholder = INTERNATIONALSTRING(@"请写下你的建议（不少于10字，不多于500字）");
}

- (IBAction)feedback:(id)sender {
    [self.contentFeedback resignFirstResponder];
    self.checkToken = YES;
//    ;
//
    if (self.contentFeedback.text.length < 10) {
        HUDNormal(INTERNATIONALSTRING(@"内容不少于10个字"))
    } else if (self.contentFeedback.text.length > 500) {
        HUDNormal(INTERNATIONALSTRING(@"内容不能多于500字"))
    } else {
        NSDictionary *info = [[NSDictionary alloc] initWithObjectsAndKeys:[[UIDevice currentDevice] systemVersion],@"Version",[[UIDevice currentDevice] model],@"Model",self.contentFeedback.text,@"Info", nil];
        [self getBasicHeader];
//        NSLog(@"表演头：%@",self.headers);
        [SSNetworkRequest postRequest:apiFeedback params:info success:^(id responseObj) {
            if ([[responseObj objectForKey:@"status"] intValue]==1) {
                NSLog(@"查询到的用户数据：%@",responseObj);
                HUDNormal(responseObj[@"msg"])
                [self.navigationController popViewControllerAnimated:YES];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            }else{
                //数据请求失败
                HUDNormal(responseObj[@"msg"])
            }
        } failure:^(id dataObj, NSError *error) {
            //
            NSLog(@"啥都没：%@",[error description]);
        } headers:self.headers];
    }
}

@end
