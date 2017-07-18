//
//  UILabel+Extension.h
//  unitoys
//
//  Created by 董杰 on 2017/5/5.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (Extension)

/**
 * 改变小数大小
 */
- (void)changeLabelTexeFontWithString:(NSString *)string;

/**
 *  改变行间距
 */
+ (void)changeLineSpaceForLabel:(UILabel *)label WithSpace:(float)space;

/**
 *  改变字间距
 */
+ (void)changeWordSpaceForLabel:(UILabel *)label WithSpace:(float)space;

/**
 *  改变行间距和字间距
 */
+ (void)changeSpaceForLabel:(UILabel *)label withLineSpace:(float)lineSpace WordSpace:(float)wordSpace;

@end
