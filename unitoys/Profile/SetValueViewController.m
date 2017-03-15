//
//  SetValueViewController.m
//  unitoys
//
//  Created by sumars on 16/11/4.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "SetValueViewController.h"

@interface SetValueViewController ()

@end

@implementation SetValueViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edtValue.text = self.name;
    
    //左边按钮
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:INTERNATIONALSTRING(@"取消") style:UIBarButtonItemStyleDone target:self action:@selector(leftButtonAction)];
    self.navigationItem.leftBarButtonItem = left;
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:INTERNATIONALSTRING(@"保存") style:UIBarButtonItemStyleDone target:self action:@selector(rightButtonAction)];
    self.navigationItem.rightBarButtonItem = right;
    
    NSMutableDictionary *textAttrs = [NSMutableDictionary dictionary];
    textAttrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
    textAttrs[NSFontAttributeName] = [UIFont systemFontOfSize:14];
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
    // Do any additional setup after loading the view.
}

- (void)leftButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)rightButtonAction {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setValue" object:self.edtValue.text];
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
