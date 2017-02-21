//
//  CallActionView.m
//  unitoys
//
//  Created by mars su on 17/1/24.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "CallActionView.h"

@interface CallActionView ()

@property (nonatomic, strong) UIWindow *bgWindow;

@end

@implementation CallActionView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

/*
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    NSLog(@"有变化哦");
}*/

- (UIWindow *)bgWindow
{
    if (!_bgWindow) {
        _bgWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _bgWindow.windowLevel = UIWindowLevelStatusBar;
        _bgWindow.backgroundColor = [UIColor clearColor];
        _bgWindow.hidden = NO;
    }
    return _bgWindow;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    self.hidden = NO;
    if (self) {
        [self.bgWindow addSubview:self];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [self addGestureRecognizer:tap];
        
        self.viewAction = [[UIView alloc] initWithFrame:CGRectMake(0, self.bgWindow.bounds.size.height-160, self.bgWindow.bounds.size.width, 160)];
        
        self.viewAction.backgroundColor = [UIColor whiteColor];
        
        self.viewAction.hidden = NO;
        
        [self addSubview:self.viewAction];
        
        self.btnNetworkCall = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, frame.size.width-20, 40)];
        self.btnNetworkCall.layer.cornerRadius = 4;
        self.btnNetworkCall.backgroundColor = [UIColor colorWithRed:54/255.0 green:189/255.0 blue:91/255.0 alpha:1];
        
        [self.btnNetworkCall setTitle:@"网络电话" forState:UIControlStateNormal];
        
        [self.btnNetworkCall setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        self.btnNetworkCall.hidden = NO;
        
        self.btnInteralCall = [[UIButton alloc] initWithFrame:CGRectMake(10, 60, frame.size.width-20, 40)];
        self.btnInteralCall.layer.cornerRadius = 4;
        self.btnInteralCall.backgroundColor = [UIColor colorWithRed:35/255.0 green:148/255.0 blue:220/255.0 alpha:1];
        
        [self.btnInteralCall setTitle:@"手环电话" forState:UIControlStateNormal];
        
        [self.btnInteralCall setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        self.btnInteralCall.hidden = NO;
        
        self.btnCancelCall = [[UIButton alloc] initWithFrame:CGRectMake(10, 110, frame.size.width-20, 40)];
        self.btnCancelCall.layer.cornerRadius = 4;
        self.btnCancelCall.backgroundColor = [UIColor colorWithRed:221/255.0 green:221/255.0 blue:221/255.0 alpha:1];
        
        [self.btnCancelCall setTitle:@"取消" forState:UIControlStateNormal];
        
        [self.btnCancelCall setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        self.btnCancelCall.hidden = NO;
        
        [self.viewAction addSubview:self.btnNetworkCall];
        [self.btnNetworkCall addTarget:self action:@selector(networkCall) forControlEvents:UIControlEventTouchUpInside];
        
        [self.viewAction addSubview:self.btnInteralCall];
        [self.btnInteralCall addTarget:self action:@selector(interalCall) forControlEvents:UIControlEventTouchUpInside];
        
        [self.viewAction addSubview:self.btnCancelCall];
        [self.btnCancelCall addTarget:self action:@selector(cancelCall) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)showActionView
{
    [self.bgWindow setHidden:NO];
    [self setHidden:NO];
}

- (void)hideActionView
{
    [self.bgWindow setHidden:YES];
    [self setHidden:YES];
}

- (void)dismissView
{
    if (_bgWindow) {
        _bgWindow.hidden = YES;
        _bgWindow = nil;
    }
}

- (void)networkCall {
    if (self.actionBlock) {
        self.actionBlock(1);
    }
}

- (void)interalCall {
    if (self.actionBlock) {
        self.actionBlock(2);
    }
}

- (void)cancelCall {
    if (self.cancelBlock) {
        self.cancelBlock();
    }
}

- (void)tapAction
{
    [self hideActionView];
}

@end
