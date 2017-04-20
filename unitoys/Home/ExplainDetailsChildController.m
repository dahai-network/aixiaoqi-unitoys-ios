//
//  ExplainDetailsChildController.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ExplainDetailsChildController.h"
#import "UNDataTools.h"
#import "global.h"
#import "BlueToothDataManager.h"
#import "ExplainDetailsLastController.h"
@interface ExplainDetailsChildController ()

@end

@implementation ExplainDetailsChildController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpCurrentVc];
    if (_currentPage == 0) {
        self.nextStepButton.enabled = YES;
        [self.nextStepButton setBackgroundColor:UIColorFromRGB(0x00a0e9)];
        self.gotoSystemButton.hidden = YES;
    }else{
        self.gotoSystemButton.hidden = NO;
        if (_currentPage <= [UNDataTools sharedInstance].currentAbroadStep) {
            self.nextStepButton.enabled = YES;
            [self.nextStepButton setBackgroundColor:UIColorFromRGB(0x00a0e9)];
        }else{
            self.nextStepButton.enabled = NO;
            [self.nextStepButton setBackgroundColor:UIColorFromRGB(0xe5e5e5)];
        }
    }
    [self.nextStepButton addTarget:self action:@selector(nextStepButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}
- (IBAction)goSystemAction:(UIButton *)sender {
    [UNDataTools sharedInstance].currentAbroadStep = _currentPage;
    self.nextStepButton.enabled = YES;
    [self.nextStepButton setBackgroundColor:UIColorFromRGB(0x00a0e9)];
}

- (void)nextStepButtonAction:(UIButton *)button
{
    button.enabled = NO;
    [self gotoNextPage];
    button.enabled = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpCurrentVc
{
    self.title = INTERNATIONALSTRING(@"出境后使用引导");
    if ([UNDataTools sharedInstance].pagesData.count - 2 < _currentPage) {
        return;
    }
    NSDictionary *dict = [UNDataTools sharedInstance].pagesData[_currentPage];
    self.pageNumber.text = [NSString stringWithFormat:@"%ld", _currentPage + 1];
    if (dict[@"nameTitle"]) {
        self.nameLabel.hidden = NO;
        self.nameLabel.text = dict[@"nameTitle"];
    }else{
        self.nameLabel.hidden = YES;
    }
    NSString *detailText = dict[@"detailTitle"];
    if (detailText) {
        self.detailLabel.hidden = NO;
        self.detailLabel.text = detailText;
        self.detailLabelHeight.constant = [self getTextHeight:detailText Margin:20 Font:self.detailLabel.font] + 10;
    }else{
        self.detailLabel.hidden = YES;
    }
    
    if (dict[@"buttonTitle"]) {
        self.gotoSystemButton.hidden = NO;
        [self.gotoSystemButton setTitle:dict[@"buttonTitle"] forState:UIControlStateNormal];
        NSString *actionStr = dict[@"buttonAction"];
        SEL action = NSSelectorFromString(actionStr);
        if ([self respondsToSelector:action]) {
            [self.gotoSystemButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        }
    }else{
        self.gotoSystemButton.hidden = YES;
    }
    
    if (dict[@"explainImage"]) {
        self.explainImageView.hidden = NO;
        self.explainImageView.image = [UIImage imageNamed:dict[@"explainImage"]];
    }else{
        self.explainImageView.hidden = YES;
    }
}

- (CGFloat)getTextHeight:(NSString *)text Margin:(CGFloat)margin Font:(UIFont *)font
{
    return [text boundingRectWithSize:CGSizeMake(kScreenWidthValue - 2 * margin, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : font} context:nil].size.height;
}

- (void)gotoNextPage
{
    if (_currentPage < _totalPage - 1) {
        ExplainDetailsChildController *detailsVc = [[ExplainDetailsChildController alloc] init];
        detailsVc.apnName = self.apnName;
        detailsVc.currentPage = self.currentPage + 1;
        detailsVc.totalPage = self.totalPage;
        detailsVc.rootClassName = self.rootClassName;
        [self.navigationController pushViewController:detailsVc animated:YES];
    }else if (_currentPage == _totalPage - 1){
        ExplainDetailsLastController *detailsVc = [[ExplainDetailsLastController alloc] init];
        detailsVc.rootClassName = self.rootClassName;
        [self.navigationController pushViewController:detailsVc animated:YES];
    }
}

- (void)apnSettingAction
{
    //访问描述文件
    NSString *textURL = [NSString stringWithFormat:@"http://localhost:%@/%@.mobileconfig", [BlueToothDataManager shareManager].localServicePort, self.apnName];
    NSURL *cleanURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", textURL]];
    NSLog(@"访问的连接为 -- %@", cleanURL);
    if (kSystemVersionValue >= 10.0) {
        NSDictionary *info = @{@"title": @"访问"};
        [[UIApplication sharedApplication] openURL:cleanURL options:info completionHandler:nil];
    }else{
        [[UIApplication sharedApplication] openURL:cleanURL];
    }
    
}

- (void)apnDeleteAction
{
    //删除APN
    //打开描述文件界面
    if (kSystemVersionValue >= 10.0) {
        NSDictionary *info = @{@"title": @"访问"};
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-prefs:root=General&path=ManagedConfigurationList"] options:info completionHandler:nil];
    }else{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-prefs:root=General&path=ManagedConfigurationList"]];
    }
}

- (void)gotoSystemSettingAction
{
    //打开app设置界面
    //    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    //打开系统设置界面
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"App-prefs:root=MOBILE_DATA_SETTINGS_ID"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-prefs:root=MOBILE_DATA_SETTINGS_ID"]];
    } else {
        NSLog(@"打不开");
    }
}

@end
