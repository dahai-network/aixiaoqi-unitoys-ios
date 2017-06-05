//
//  NotifyTextField.h
//  unitoys
//
//  Created by sumars on 16/12/21.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol  NotifyTextFieldDelegate<NSObject>

@optional
- (BOOL)unTextFieldDeleteBackward:(UITextField *)textField ChangeRange:(NSRange)range;
- (void)unTextFieldDidEndEditing:(UITextField *)textField;
- (void)unTextFieldDidBeginEditing:(UITextField *)textField;

@end

@interface NotifyTextField : UITextField

@property (nonatomic, assign)id<NotifyTextFieldDelegate>notifyTextFieldDelegate;

//- (NSRange) selectedRange;
//- (void) setSelectedRange:(NSRange) range;

@end
