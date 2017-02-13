//
//  PhoneOperationPad.m
//  unitoys
//
//  Created by sumars on 16/12/8.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "PhoneOperationPad.h"

@implementation PhoneOperationPad

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (IBAction)switchNumberPad:(id)sender {
    if (self.switchStatusBlock) {
        self.isPadHidden = !self.isPadHidden;
        self.switchStatusBlock(self.isPadHidden);
    }
}

- (IBAction)callout:(id)sender {
    if (self.calloutBlock) {
        self.calloutBlock();
    }
    /*
    NSString *number = sender;
    
    if (!self.callActionView){
        self.callActionView = [[CallActionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        
        [self addSubview:self.callActionView];
    }
    
    
    __weak typeof(self) weakSelf = self;
    
    self.callActionView.cancelBlock = ^(){
        weakSelf.callActionView.hidden = YES;
    };
    
    self.callActionView.actionBlock = ^(NSInteger callType){
        weakSelf.callActionView.hidden = YES;
        if (callType==1) {
            //网络电话
            //电话记录，拨打电话
            if (number) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeCallAction" object:number];
            }
        }else if (callType==2){
            //手环电话
            if (number) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeUnitysCallAction" object:number];
            }
        }
    };
    
    self.callActionView.hidden = NO;
    */
}

- (IBAction)deleteNumber:(id)sender {
    if (self.deleteNumberBlock) {
        self.deleteNumberBlock();
    }
}
@end
