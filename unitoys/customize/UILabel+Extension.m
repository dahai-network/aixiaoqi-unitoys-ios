//
//  UILabel+Extension.m
//  unitoys
//
//  Created by 董杰 on 2017/5/5.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UILabel+Extension.h"

@implementation UILabel (Extension)

- (void)changeLabelTexeFontWithString:(NSString *)string {
    NSMutableAttributedString *textstr = [[NSMutableAttributedString alloc] initWithString:string];
    if ([string containsString:@"."]) {
        if (string.length) {
            NSRange range1=[string rangeOfString:@"."];
            NSRange range2=NSMakeRange(1, range1.location-1);
            [textstr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:21] range:range2];
        }
    } else {
        [textstr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:21] range:NSMakeRange(1, string.length-1)];
    }
    self.attributedText=textstr;
}

@end
