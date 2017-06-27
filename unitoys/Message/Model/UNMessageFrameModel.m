//
//  UNMessageFrameModel.m
//  unitoys
//
//  Created by 黄磊 on 2017/6/26.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNMessageFrameModel.h"

@implementation UNMessageFrameModel
+ (UNMessageFrameModel *)modelWithMessage:(UNMessageModel *)message lastMessage:(UNMessageModel *)lastMessage
{
    UNMessageFrameModel *messageFrame = [[UNMessageFrameModel alloc] init];
    [messageFrame setMessage:message];
    if (lastMessage) {
        messageFrame.message.hideTime = [message.SMSTime isEqualToString:lastMessage.SMSTime];
    }
    return messageFrame;
}


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
    return [text boundingRectWithSize:maxSize options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
}

- (void)setMessage:(UNMessageModel *)message
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
    
    CGFloat containerX;
    CGFloat containerY;
    CGFloat containerW;
    CGFloat containerH;
    if (message.type == MJMessageTypeMe) {
        _contentEdge = UIEdgeInsetsMake(5, 11, 5, 15);
    }else{
        _contentEdge = UIEdgeInsetsMake(5, 15, 5, 11);
    }
    containerY = CGRectGetMaxY(_timeF);
    CGSize textMaxSize = CGSizeMake(screenW * 3.0 / 4.0, MAXFLOAT);
    CGSize contentSize = [self sizeWithText:message.SMSContent font:MJTextFont maxSize:textMaxSize];
    if (contentSize.width < 15) {
        contentSize.width = 15;
    }
    containerW = contentSize.width + _contentEdge.left + _contentEdge.right;
    containerH = contentSize.height + _contentEdge.top + _contentEdge.bottom;
    if (message.type == MJMessageTypeOther) {
        containerX= padding;
    }else{
        containerX = screenW - padding - containerW;
    }
    UNDebugLogVerbose(@"%.2f", containerH);
    _containerViewF = CGRectMake(containerX, containerY, containerW, containerH);
    
    // 4.cell的高度
    CGFloat textMaxY = CGRectGetMaxY(_containerViewF);
    _cellHeight = textMaxY + padding;  //正文和头像的最大Y值的较大者加上间距就是cell的高度
}
@end
