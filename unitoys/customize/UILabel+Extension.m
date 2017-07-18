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
//    NSString *oldPriceString = @"原价:￥99.99";
//    NSString* prceString = [NSString stringWithFormat:@"%@  %@",string,oldPriceString];
//    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:prceString];
//    
//    if ([string containsString:@"."]) {
//        if (string.length) {
//            NSRange range1=[string rangeOfString:@"."];
//            NSRange range2=NSMakeRange(1, range1.location-1);
//            [attributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:21] range:range2];
//        }
//    } else {
//        [attributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:21] range:NSMakeRange(1, string.length-1)];
//    }
//    self.attributedText=attributedString;
//    
//    
//    [attributedString addAttributes:@{
//                             NSStrikethroughStyleAttributeName:@(NSUnderlineStyleThick),
//                             NSForegroundColorAttributeName:
//                                 [UIColor lightGrayColor],
//                             NSBaselineOffsetAttributeName:
//                                 @(0),
//                             NSFontAttributeName: [UIFont systemFontOfSize:14]
//                             } range:[prceString rangeOfString:oldPriceString]];
//    
//    self.attributedText=attributedString;
    
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

+ (void)changeLineSpaceForLabel:(UILabel *)label WithSpace:(float)space {
    NSString *labelText = label.text;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:labelText];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:space];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [labelText length])];
    label.attributedText = attributedString;
    [label sizeToFit];
}

+ (void)changeWordSpaceForLabel:(UILabel *)label WithSpace:(float)space {
    NSString *labelText = label.text;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:labelText attributes:@{NSKernAttributeName:@(space)}];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [labelText length])];
    label.attributedText = attributedString;
    [label sizeToFit];
}

+ (void)changeSpaceForLabel:(UILabel *)label withLineSpace:(float)lineSpace WordSpace:(float)wordSpace {
    NSString *labelText = label.text;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:labelText attributes:@{NSKernAttributeName:@(wordSpace)}];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:lineSpace];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [labelText length])];
    label.attributedText = attributedString;
    [label sizeToFit];
}

@end
