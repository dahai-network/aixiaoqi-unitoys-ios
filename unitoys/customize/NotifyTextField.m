//
//  NotifyTextField.m
//  unitoys
//
//  Created by sumars on 16/12/21.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "NotifyTextField.h"

@implementation NotifyTextField

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)deleteBackward
{
    if (![[self.text substringWithRange:NSMakeRange(self.selectedRange.location-1, 1)] isEqualToString:@" "]) {
        [super deleteBackward];
    }
    
    if ((_notifyTextFieldDelegate &&[_notifyTextFieldDelegate respondsToSelector:@selector(deleteBackward)]))
    {
        [_notifyTextFieldDelegate deleteBackward];
    }
}

- (NSRange) selectedRange
{
    UITextPosition* beginning = self.beginningOfDocument;
    
    UITextRange* selectedRange = self.selectedTextRange;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    
    const NSInteger location = [self offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [self offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

- (void) setSelectedRange:(NSRange) range  // 备注：UITextField必须为第一响应者才有效
{
    UITextPosition* beginning = self.beginningOfDocument;
    
    UITextPosition* startPosition = [self positionFromPosition:beginning offset:range.location];
    UITextPosition* endPosition = [self positionFromPosition:beginning offset:range.location + range.length];
    UITextRange* selectionRange = [self textRangeFromPosition:startPosition toPosition:endPosition];
    
    [self setSelectedTextRange:selectionRange];
}

@end
