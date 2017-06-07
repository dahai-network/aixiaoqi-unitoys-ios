//
//  UNMobileActivateController.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/7.
//  Copyright © 2017年 sumars. All rights reserved.
//

#define ContentPaddingX 5

#import "UNMobileActivateController.h"


@interface UNMobileActivateController ()<UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIScrollView *contentView;

@property (nonatomic, copy) NSArray *totalDatas;
@property (nonatomic, assign) NSInteger currentPage;

@property (nonatomic, assign) CGFloat contentWidth;
@property (nonatomic, assign) CGFloat contentHeight;
@end

@implementation UNMobileActivateController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"手机内激活引导";
    [self.nextButton addTarget:self action:@selector(nextPageAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.backButton addTarget:self action:@selector(backPageAction:) forControlEvents:UIControlEventTouchUpInside];
    self.totalDatas = @[
                        @{
                            @"indexImageName" : @"desc_01",
                            @"title" : @"程序将打开设置中的电话页面,请选择SIM卡应用程序",
                            @"imageName" : @"image_ios_01",
                          },
                        @{
                            @"indexImageName" : @"desc_02",
                            @"title" : @"请激活爱小器卡",
                            @"imageName" : @"image_ios_02",
                            },
                        @{
                            @"indexImageName" : @"desc_03",
                            @"title" : @"我们已将激活码复制,请在文本输入位置长按,弹出粘贴后,粘贴即可",
                            @"imageName" : @"image_ios_03",
                            },
                        @{
                            @"indexImageName" : @"desc_04",
                            @"title" : @"数据正确,请点击接受,即完成爱小器激活",
                            @"imageName" : @"image_ios_04",
                            },
                        ];
    self.currentPage = 0;
    [self initContentView];
}

- (void)initContentView
{
    self.contentHeight = kScreenHeightValue - 125 - 85 - 64;
    self.contentWidth = (600.0/850)*self.contentHeight;
    [self.contentView setContentSize:CGSizeMake(self.contentWidth * self.totalDatas.count + (self.totalDatas.count - 1) * ContentPaddingX, self.contentHeight)];
    CGFloat contentX;
    for (int i = 0; i < self.totalDatas.count; i++) {
        NSDictionary *data = self.totalDatas[i];
        contentX = (self.contentWidth + ContentPaddingX)  * i;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(contentX, 0, self.contentWidth, self.contentHeight)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.image = [UIImage imageNamed:data[@"imageName"]];
        [self.contentView addSubview:imageView];
    }
    [self updateViewData];
}

- (void)nextPageAction:(UIButton *)button
{
    if (_currentPage == self.totalDatas.count - 1) {
        [self gotoSystemSetting];
    }else{
        _currentPage++;
        [self updateViewData];
    }
}

- (void)backPageAction:(UIButton *)button
{
    if (_currentPage == 0) {
        NSLog(@"什么鬼");
        button.hidden = YES;
    }else{
        _currentPage--;
        [self updateViewData];
    }
}

- (void)updateViewData
{
    if (_currentPage >= 0 && _currentPage < self.totalDatas.count) {
        NSDictionary *data = self.totalDatas[_currentPage];
        self.imageView.image = [UIImage imageNamed:data[@"indexImageName"]];
        self.titleLabel.text = data[@"title"];
        [self.contentView setContentOffset:CGPointMake((self.contentWidth + ContentPaddingX) * _currentPage, 0) animated:YES];
        if(_currentPage == 0){
            self.backButton.hidden = YES;
            [self.nextButton setTitle:@"下一步" forState:UIControlStateNormal];
        }else{
            self.backButton.hidden = NO;
            if (_currentPage == self.totalDatas.count - 1) {
                [self.nextButton setTitle:@"已了解去操作" forState:UIControlStateNormal];
            }else{
                [self.nextButton setTitle:@"下一步" forState:UIControlStateNormal];
            }
        }
    }else{
        NSLog(@"什么鬼");
    }
}

- (void)gotoSystemSetting
{
    NSLog(@"系统设置");
    if (kSystemVersionValue >= 8.0) {
        if (kSystemVersionValue >= 10.0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=Phone"] options:@{}     completionHandler:nil];
        }else{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=Phone"]];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
