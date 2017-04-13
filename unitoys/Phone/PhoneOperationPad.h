//
//  PhoneOperationPad.h
//  unitoys
//
//  Created by sumars on 16/12/8.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CallActionView.h"

@interface PhoneOperationPad : UIView

@property (weak, nonatomic) IBOutlet UIButton *btnSwitchNumberPad;
//@property (weak, nonatomic) IBOutlet UIButton *btnDelNumber;
//@property (nonatomic, strong) CallActionView *callActionView;

@property (readwrite) BOOL isPadHidden;

- (IBAction)switchNumberPad:(id)sender;
- (IBAction)callout:(id)sender;
//- (IBAction)deleteNumber:(id)sender;


typedef void (^SwitchStatusBlock)(BOOL hidden);
@property (nonatomic,copy)SwitchStatusBlock switchStatusBlock;

//typedef void (^DeleteNumberBlock)();
//@property (nonatomic,copy)DeleteNumberBlock deleteNumberBlock;

typedef void (^CalloutBlock)();
@property (nonatomic,copy)CalloutBlock calloutBlock;

@end
