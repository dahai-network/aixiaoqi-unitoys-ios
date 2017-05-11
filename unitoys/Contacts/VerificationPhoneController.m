//
//  VerificationPhoneController.m
//  unitoys
//
//  Created by 黄磊 on 2017/5/11.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "VerificationPhoneController.h"
#import "UNPushKitMessageManager.h"

@interface VerificationPhoneController ()
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@end

@implementation VerificationPhoneController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}
- (IBAction)verificationAction:(UIButton *)sender {
    sender.enabled = NO;
    //验证
    sender.enabled = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
