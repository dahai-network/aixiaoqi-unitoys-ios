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


//- (void)deleteBackward
//{
//    if (![[self.text substringWithRange:NSMakeRange(self.selectedRange.location-1, 1)] isEqualToString:@"、"]) {
//        [super deleteBackward];
//    }
//    
////    if ((_notifyTextFieldDelegate &&[_notifyTextFieldDelegate respondsToSelector:@selector(deleteBackward)]))
////    {
////        [_notifyTextFieldDelegate deleteBackward];
////    }
//}


//- (NSRange) selectedRange
//{
//    UITextPosition* beginning = self.beginningOfDocument;
//    
//    UITextRange* selectedRange = self.selectedTextRange;
//    UITextPosition* selectionStart = selectedRange.start;
//    UITextPosition* selectionEnd = selectedRange.end;
//    
//    const NSInteger location = [self offsetFromPosition:beginning toPosition:selectionStart];
//    const NSInteger length = [self offsetFromPosition:selectionStart toPosition:selectionEnd];
//    
//    return NSMakeRange(location, length);
//}
//
//- (void) setSelectedRange:(NSRange) range  // 备注：UITextField必须为第一响应者才有效
//{
//    UITextPosition* beginning = self.beginningOfDocument;
//    
//    UITextPosition* startPosition = [self positionFromPosition:beginning offset:range.location];
//    UITextPosition* endPosition = [self positionFromPosition:beginning offset:range.location + range.length];
//    UITextRange* selectionRange = [self textRangeFromPosition:startPosition toPosition:endPosition];
//    
//    [self setSelectedTextRange:selectionRange];
//}

@end
