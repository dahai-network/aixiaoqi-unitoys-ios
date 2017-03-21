//
//  BrowserViewController.m
//  unitoys
//
//  Created by sumars on 16/9/26.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BrowserViewController.h"

@interface BrowserViewController ()<UIWebViewDelegate>

@end

@implementation BrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.titleStr && ![self.titleStr isEqualToString:@"null"]) {
        self.title = self.titleStr;
    } else {
        self.title = INTERNATIONALSTRING(@"广告");
    }
    self.webview.delegate = self;
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.loadUrl]]];
    // Do any additional setup after loading the view.
}

#pragma mark - 代理方法
#pragma mark 开始加载的时候调用
- (void)webViewDidStartLoad:(UIWebView *)webView {
    //    创建UIActivityIndicatorView背景半透明View
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [view setTag:108];
    [view setBackgroundColor:[UIColor blackColor]];
    [view setAlpha:0.2];
    [self.view addSubview:view];
    
    UIActivityIndicatorView *act = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    //    设置缓冲标志的位置
    act.center = view.center;
    //    设置缓冲标志的样式
    [act setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [view addSubview:act];
    
    [act startAnimating];
}

#pragma mark 加载失败的时候调用
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    //    取消View
    UIActivityIndicatorView *act = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [act stopAnimating];
    UIView *view = [self.view viewWithTag:108];
    [view removeFromSuperview];
    [self showAlertWithMessage:INTERNATIONALSTRING(@"加载失败")];
    return;
}

#pragma mark 加载完成的时候调用
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    //    取消View
    UIActivityIndicatorView *act = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [act stopAnimating];
    UIView *view = [self.view viewWithTag:108];
    [view removeFromSuperview];
}

- (void)showAlertWithMessage:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *certailAction = [UIAlertAction actionWithTitle:INTERNATIONALSTRING(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertVC addAction:certailAction];
    [self presentViewController:alertVC animated:YES completion:nil];
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
