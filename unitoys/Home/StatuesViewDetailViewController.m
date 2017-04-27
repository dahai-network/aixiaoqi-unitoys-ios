//
//  StatuesViewDetailViewController.m
//  unitoys
//
//  Created by 董杰 on 2017/4/27.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "StatuesViewDetailViewController.h"
#import "BlueToothDataManager.h"

@interface StatuesViewDetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@end

@implementation StatuesViewDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"详情";
    self.detailLabel.text = [BlueToothDataManager shareManager].statuesTitleString;
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
