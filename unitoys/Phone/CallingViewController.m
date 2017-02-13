//
//  CallingViewController.m
//  CloudEgg
//
//  Created by sumars on 16/2/24.
//  Copyright © 2016年 ququ-iOS. All rights reserved.
//

#import "CallingViewController.h"

@interface CallingViewController ()

@end

@implementation CallingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCallingMessage:) name:@"CallingMessage" object:nil];
}

- (void)getCallingMessage :(NSNotification *)notification {
    if (notification.object) {
        self.lblCallingHint.text = notification.object;
        if ([self.lblCallingHint.text isEqualToString:@"对方振铃..."]) {
            self.hadRing = YES;
            
            if (self.isHandfree) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"SwitchSound"];
            }
            
            if (self.isMute) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"MuteSound"];
            }
        }
        
        if ([self.lblCallingHint.text isEqualToString:@"呼叫接通"]) {
            self.callingStatus = YES;
            
            
        }else if ([self.lblCallingHint.text isEqualToString:@"正在通话"]) {
            self.callingStatus = YES;
            
            if (!self.callTimer) {
                //开始计时
                self.callTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(displayTime) userInfo:nil repeats:YES];
            }
            
        }else if([self.lblCallingHint.text isEqualToString:@"通话结束"]){
            //关掉当前
            if (self.callTimer) {
                [self.callTimer setFireDate:[NSDate distantFuture]];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        }else{
            self.callingStatus = NO;
        }
    }
}

- (void)displayTime {
    self.callSeconds +=1;
    self.lblCallingHint.text = [NSString stringWithFormat:@"%02d:%02d",self.callSeconds/60,self.callSeconds%60];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (IBAction)muteCalling:(id)sender {
    if (self.hadRing){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"MuteSound"];
        
    }else{
        self.isMute = !self.isMute;
    }
    
    if (_btnMuteStatus.tag==0) {
        [_btnMuteStatus setImage:[UIImage imageNamed:@"tel_muteon"] forState:UIControlStateNormal];
        _btnMuteStatus.tag=1;
    } else {
        [_btnMuteStatus setImage:[UIImage imageNamed:@"tel_muteoff"] forState:UIControlStateNormal];
        _btnMuteStatus.tag=0;
    }
}

- (IBAction)handfreeCalling:(id)sender {
    if (self.hadRing){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"SwitchSound"];
        
    }else{
        self.isHandfree = !self.isHandfree;
    }
    
    if (_btnSpeakerStatus.tag==0) {
        [_btnSpeakerStatus setImage:[UIImage imageNamed:@"tel_handfreeon"] forState:UIControlStateNormal];
        _btnSpeakerStatus.tag=1;
    } else {
        [_btnSpeakerStatus setImage:[UIImage imageNamed:@"tel_handfreeoff"] forState:UIControlStateNormal];
        _btnSpeakerStatus.tag=0;
    }
}

- (IBAction)hungupCalling:(id)sender {
    self.hadRing = NO;
     [[NSNotificationCenter defaultCenter] postNotificationName:@"CallingAction" object:@"Hungup"];
}
@end
