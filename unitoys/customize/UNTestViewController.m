//
//  UNTestViewController.m
//  unitoys
//
//  Created by 黄磊 on 2017/4/21.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNTestViewController.h"
#import "global.h"
#import "UNPresentTool.h"

@interface UNTestViewController ()
@property (nonatomic, strong) UNPresentTool *presentTool;
@end

@implementation UNTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = DefultColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Present" style:UIBarButtonItemStyleDone target:self action:@selector(presentVc)];
}

- (void)presentVc
{
    [self initPopView];
}

- (void)initPopView
{
    if (!_presentTool) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidthValue - 100, kScreenWidthValue - 100)];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [view addGestureRecognizer:tap];
        view.backgroundColor = [UIColor redColor];
        [self.view addSubview:view];
        _presentTool = [UNPresentTool new];
        [_presentTool presentContentView:view duration:0.85 inView:self.view];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tapAction
{
    if (_presentTool) {
        [_presentTool dismissDuration:0.5];
        _presentTool = nil;
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
