//
//  LookLogContentController.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/19.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "LookLogContentController.h"

@interface LookLogContentController ()

@end

@implementation LookLogContentController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.contentTextView.text = self.text;
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
