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
//        self.isPadHidden = !self.isPadHidden;
        self.switchStatusBlock(YES);
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


//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//    UIView *view = [super hitTest:point withEvent:event];
//    if (view == nil) {
//        for (UIView *subView in self.subviews) {
//            if ([subView isKindOfClass:[UIButton class]]) {
//                if (!subView.isHidden) {
//                    CGPoint p = [subView convertPoint:point fromView:self];
//                    if (CGRectContainsPoint(subView.bounds, p)) {
//                        view = subView;
////                        for (UIView *subView2 in subView.subviews) {
////                            CGPoint p2 = [subView2 convertPoint:p fromView:subView];
////                            if (CGRectContainsPoint(subView2.bounds, p2)) {
////                                view = subView2;
////                            }
////                        }
//                    }
//                }
//            }
//        }
//    }
//    UNDebugLogVerbose(@"PhoneOperationPad-hitTest-------%@", view);
//    return view;
//}

@end
