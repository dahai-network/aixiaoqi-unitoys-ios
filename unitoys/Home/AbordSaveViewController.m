//
//  AbordSaveViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/4/26.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "AbordSaveViewController.h"
#import "SDCycleScrollView.h"

@interface AbordSaveViewController ()
@property (weak, nonatomic) IBOutlet SDCycleScrollView *detailView;

@end

@implementation AbordSaveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"海外节费引导";
    NSArray *imageArr = @[@"ios_001", @"ios_002", @"ios_003"];
    self.detailView.localizationImageNamesGroup = imageArr;
    self.detailView.currentPageDotColor = UIColorFromRGB(0x00a0e9);
    self.detailView.pageDotColor = UIColorFromRGB(0xf5f5f5);
    self.detailView.infiniteLoop = NO;
    self.detailView.autoScroll = NO;
    // Do any additional setup after loading the view from its nib.
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
