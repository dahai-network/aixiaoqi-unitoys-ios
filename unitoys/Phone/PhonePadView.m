//
//  PhonePadView.m
//  CloudEgg
//
//  Created by ququ-iOS on 16/2/19.
//  Copyright © 2016年 ququ-iOS. All rights reserved.
//

#import "PhonePadView.h"

@implementation PhonePadView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/



- (IBAction)delPhoneStr:(id)sender {
    if (self.inputedPhoneNumber.length>0) {
        self.inputedPhoneNumber = [self.inputedPhoneNumber substringToIndex:self.inputedPhoneNumber.length-1];
    }
}

- (IBAction)inputPhoneStr:(id)sender {
    UIButton *btnSender  = (UIButton *)sender;
    if (btnSender) {
        NSString *sendchar = btnSender.titleLabel.text;
        if (self.inputedPhoneNumber.length>0){
            self.inputedPhoneNumber = [self.inputedPhoneNumber stringByAppendingString:sendchar];
        }else{
            self.inputedPhoneNumber = sendchar;
        }
    }
    
    if (self.completeBlock) {
        self.completeBlock(btnSender.titleLabel.text,btnSender.tag);
    }
}
- (IBAction)delelePhoneStr:(id)sender {
    /*
    UIButton *btnSender  = (UIButton *)sender;
    
    if (btnSender) {
        if (self.lblPhoneNumber.text.length>0) {
            self.lblPhoneNumber.text = [self.lblPhoneNumber.text substringToIndex:self.lblPhoneNumber.text.length-1];
        }
    }
    
    if (self.completeBlock) {
        self.completeBlock(btnSender.titleLabel.text,btnSender.tag);
    } */
}
@end
