//
//  MJMessageFrame.m
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "MJMessageFrame.h"
#import "MJMessage.h"

@implementation MJMessageFrame
/**
 *  计算文字尺寸
 *
 *  @param text    需要计算尺寸的文字
 *  @param font    文字的字体
 *  @param maxSize 文字的最大尺寸
 */
- (CGSize)sizeWithText:(NSString *)text font:(UIFont *)font maxSize:(CGSize)maxSize
{
    NSDictionary *attrs = @{NSFontAttributeName : font};
    return [text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
}

- (void)setMessage:(MJMessage *)message
{
    _message = message;
    // 间距
    CGFloat padding = 10;
    // 屏幕的宽度
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    
    // 1.时间
    CGFloat timeX = 0;
    CGFloat timeY = 0;
    CGFloat timeW = screenW;
    CGFloat timeH = 40;
    _timeF = CGRectMake(timeX, timeY, timeW, timeH); //因为timeF属性是readonly的所以没有自动生成set方法  所以不能用点语法  所以用_timeF
    
    // 2.头像
    CGFloat iconY = CGRectGetMaxY(_timeF);  //头像的y值就是时间的最大Y值
    CGFloat iconW = 0;
    CGFloat iconH = 0;
    CGFloat iconX;
    if (message.type == MJMessageTypeOther) {// 别人发的
        iconX = padding;
    } else { // 自己的发的
        iconX = screenW - padding - iconW;
    }
    _iconF = CGRectMake(iconX, iconY, iconW, iconH);
    
    // 3.正文
    CGFloat textY = iconY;
    // 文字的尺寸
    CGSize textMaxSize = CGSizeMake(250, MAXFLOAT);  //文字不限高度 ，要限制宽度
    CGSize textSize = [self sizeWithText:message.text font:MJTextFont maxSize:textMaxSize];
    CGFloat textX;
    if (message.type == MJMessageTypeOther) {// 别人发的
        textX = CGRectGetMaxX(_iconF) + padding;
    } else {// 自己的发的
        textX = iconX - padding - textSize.width;
    }
    //    _textF = CGRectMake(textX, textY, textSize.width, textSize.height);
    
    textSize = CGSizeMake(textSize.width+20, textSize.height+10);
    _textF = (CGRect){{textX, textY}, textSize};
    
    // 4.cell的高度
    CGFloat textMaxY = CGRectGetMaxY(_textF);
    CGFloat iconMaxY = CGRectGetMaxY(_iconF);
    _cellHeight = MAX(textMaxY, iconMaxY) + padding;  //正文和头像的最大Y值的较大者加上间距就是cell的高度
}

@end
