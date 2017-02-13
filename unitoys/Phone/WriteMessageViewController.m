//
//  WriteMessageViewController.m
//  unitoys
//
//  Created by sumars on 16/10/9.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "WriteMessageViewController.h"

@interface WriteMessageViewController ()

@end

@implementation WriteMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (IBAction)addReceiveMan:(id)sender {
}

- (IBAction)sendMessage:(id)sender {
    
    if ([self.txtReceiveMan.text length]>3) {
        self.checkToken = YES;
        NSString *receiveNumbers = self.txtReceiveMan.text;
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:receiveNumbers,@"To",self.txtMessageContent.text,@"SMSContent", nil];
        
        [self getBasicHeader];
        NSLog(@"表演头：%@",self.headers);
        [SSNetworkRequest postRequest:apiSMSSend params:params success:^(id responseObj) {
            
            NSLog(@"查询到的用户数据：%@",responseObj);
            
            
            if ([[responseObj objectForKey:@"status"] intValue]==0) {
                [[[UIAlertView alloc] initWithTitle:@"系统提示" message:[responseObj objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            }else if ([[responseObj objectForKey:@"status"] intValue]==-999){
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloginNotify" object:nil];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"发送成功" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            }
        } failure:^(id dataObj, NSError *error) {
            //
            NSLog(@"啥都没：%@",[error description]);
        } headers:self.headers];
    }
}



@end
