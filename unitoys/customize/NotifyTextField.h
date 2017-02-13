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
- (void)deleteBackward;

@end

@interface NotifyTextField : UITextField

@property (nonatomic, assign)id<NotifyTextFieldDelegate>notifyTextFieldDelegate;

- (NSRange) selectedRange;
- (void) setSelectedRange:(NSRange) range;

@end
