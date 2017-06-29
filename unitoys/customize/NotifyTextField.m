//
//  NotifyTextField.m
//  unitoys
//
//  Created by sumars on 16/12/21.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "NotifyTextField.h"
#import "UNConvertFormatTool.h"

@interface NotifyTextField()<UITextFieldDelegate>

@end

@implementation NotifyTextField

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initSubViews];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews
{
    self.delegate = self;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSLog(@"string==%@", string);
    if (string.length == 0 && range.length != 0) {
        //判断是否在删除内容
        return [self deleteBackwardNoti:textField ChangeRange:range];
    }else if(range.length == 0 && string.length == 1){
        //强制只能在最后输入
        if (range.location == textField.text.length) {
            if ([UNConvertFormatTool isAllNumberWithString:string] || [string isEqualToString:@","] || [string isEqualToString:@"，"]) {
                return YES;
            }else{
                return NO;
            }
        }else{
            return NO;
        }
    }else{
        return NO;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self endEditing:YES];
    return YES;
}

- (BOOL)deleteBackwardNoti:(UITextField *)textField ChangeRange:(NSRange)range
{
    if ([self.notifyTextFieldDelegate respondsToSelector:@selector(unTextFieldDeleteBackward:ChangeRange:)]) {
        return [self.notifyTextFieldDelegate unTextFieldDeleteBackward:textField ChangeRange:range];
    }
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([self.notifyTextFieldDelegate respondsToSelector:@selector(unTextFieldDidEndEditing:)]) {
        [self.notifyTextFieldDelegate unTextFieldDidEndEditing:textField];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([self.notifyTextFieldDelegate respondsToSelector:@selector(unTextFieldDidBeginEditing:)]) {
        [self.notifyTextFieldDelegate unTextFieldDidBeginEditing:textField];
    }
}

@end
