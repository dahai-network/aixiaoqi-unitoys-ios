//
//  ExplainDetailsLastController.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/20.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "ExplainDetailsLastController.h"
#import "UNDataTools.h"

@interface ExplainDetailsLastController ()

@end

@implementation ExplainDetailsLastController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = INTERNATIONALSTRING(@"出境后使用引导");
    self.titleLabel.text = [UNDataTools sharedInstance].pagesData.lastObject[@"detailTitle"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
- (IBAction)nextStepAction:(UIButton *)sender {
    sender.enabled = NO;
    [self gotoNextPage];
    sender.enabled = YES;
}

- (void)gotoNextPage
{
    UIViewController *popVc;
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:NSClassFromString(self.rootClassName)]) {
            popVc = vc;
        }
    }
    if (popVc) {
        [self.navigationController popToViewController:popVc animated:YES];
    }
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
