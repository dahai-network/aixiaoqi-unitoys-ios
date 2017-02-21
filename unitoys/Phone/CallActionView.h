//
//  CallActionView.h
//  unitoys
//
//  Created by mars su on 17/1/24.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CallActionView : UIView

@property (strong,nonatomic) UIView *viewAction;
@property (strong,nonatomic) UIButton *btnNetworkCall;
@property (strong,nonatomic) UIButton *btnInteralCall;
@property (strong,nonatomic) UIButton *btnCancelCall;

typedef void (^CallActionBlock)(NSInteger callType);
@property (nonatomic,copy)CallActionBlock actionBlock;

typedef void (^CallCancelBlock)();
@property (nonatomic,copy)CallCancelBlock cancelBlock;

- (void)showActionView;
- (void)hideActionView;

- (void)dismissView;

@end
