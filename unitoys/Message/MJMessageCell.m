//
//  MJMessageCell.m
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "MJMessageCell.h"
#import "MJMessageFrame.h"
#import "MJMessage.h"

#import "UIImage+Extension.h"
#import "global.h"

@interface MJMessageCell()
{
    UILongPressGestureRecognizer *_longPressGesture;
}

/**
 *  时间
 */
@property (nonatomic, weak) UILabel *timeView;
///**
// *  头像
// */
//@property (nonatomic, weak) UIImageView *iconView;
///**
// *  正文
// */
//@property (nonatomic, weak) UIButton *textView;

@property (nonatomic, copy) NSString *content;

/**
 *  容器
 */
@property (nonatomic, weak) UIView *containerView;

/**
 *  正文背景
 */
@property (nonatomic, weak) UIImageView *bgImageView;

/**
 *  正文
 */
@property (nonatomic, weak) UILabel *contentLabel;

@end

@implementation MJMessageCell
+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *ID = @"message";
    MJMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[MJMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    return cell;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // 子控件的创建和初始化
        // 1.时间
        UILabel *timeView = [[UILabel alloc] init];   //因为这个属性定义的是弱指针类型的  所以这行代码过后就会被销毁   所以先用一个强指针指向刚创建的这个对象然后把它添加到contentView中
        //        timeView.backgroundColor = [UIColor redColor];
        timeView.textAlignment = NSTextAlignmentCenter;
        timeView.textColor = [UIColor darkGrayColor];
        timeView.font = [UIFont systemFontOfSize:13];
        [self.contentView addSubview:timeView];  //把刚创建的那个lable对象添加到contentView中
        self.timeView = timeView;
        
        // 2.头像
//        UIImageView *iconView = [[UIImageView alloc] init];
//        [self.contentView addSubview:iconView];
//        self.iconView = iconView;
        
        // 3.正文
//        UIButton *textView = [[UIButton alloc] init];
//        textView.titleLabel.numberOfLines = 0; // 自动换行
////        textView.backgroundColor = [UIColor purpleColor];
//        textView.titleLabel.font = MJTextFont;
////        textView.titleLabel.textColor = [UIColor blackColor];
//        [self.contentView addSubview:textView];
//        self.textView = textView;
        
        
        UIView *containerView = [[UIView alloc] init];
        self.containerView = containerView;
        [self.contentView addSubview:containerView];
        
        UIImageView *bgImageView = [[UIImageView alloc] init];
        self.bgImageView = bgImageView;
        [containerView addSubview:bgImageView];
        
        UILabel *contentLabel = [[UILabel alloc] init];
        self.contentLabel = contentLabel;
        contentLabel.userInteractionEnabled = YES;
        contentLabel.font = MJTextFont;
        contentLabel.numberOfLines = 0;
        [containerView addSubview:contentLabel];
        
        // 4.设置cell的背景色
        self.backgroundColor = [UIColor clearColor];
        
        [self makeGesture];
    }
    return self;
}

- (void)makeGesture
{
    if (!_longPressGesture) {
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureAction:)];
        [self.contentLabel addGestureRecognizer:_longPressGesture];
    }
}

- (void)longPressGestureAction:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        kWeakSelf
        if (_longPressCellBlock) {
            _longPressCellBlock(weakSelf.contentLabel.text, weakSelf.containerView);
        }
    }
}

- (void)setMessageFrame:(MJMessageFrame *)messageFrame
{
    _messageFrame = messageFrame;
    
    MJMessage *message = messageFrame.message;
    
    // 1.时间
    self.timeView.text = message.time;
    self.timeView.frame = messageFrame.timeF;
    
    // 2.头像
//    NSString *icon = (message.type == MJMessageTypeMe) ? @"me" : @"other";
//    self.iconView.image = [UIImage imageNamed:icon];
//    self.iconView.frame = messageFrame.iconF;
    
    // 3.正文
//    [self.textView setTitle:message.text forState:UIControlStateNormal];
//    self.textView.frame = messageFrame.textF;

    self.contentLabel.text = message.text;
    self.containerView.frame = messageFrame.containerViewF;
    self.bgImageView.frame = self.containerView.bounds;
    self.contentLabel.frame = CGRectMake(messageFrame.contentEdge.left, messageFrame.contentEdge.top, messageFrame.containerViewF.size.width - messageFrame.contentEdge.left - messageFrame.contentEdge.right, messageFrame.containerViewF.size.height - messageFrame.contentEdge.top - messageFrame.contentEdge.bottom);
    if (message.type == MJMessageTypeMe) {
        [self.bgImageView setImage:[UIImage resizableImage:@"msg_send"]];
        [self.contentLabel setTextColor:[UIColor whiteColor]];
    }else{
        [self.bgImageView setImage:[UIImage resizableImage1:@"msg_receive"]];
        [self.contentLabel setTextColor:[UIColor blackColor]];
    }
    
    
    // 4.正文的背景(设置拉升效果）
//    if (message.type == MJMessageTypeMe) { // 自己发的,蓝色
//        [self.textView setBackgroundImage:[UIImage resizableImage:@"msg_send"] forState:UIControlStateNormal];
//        [self.textView setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//        
//    } else { // 别人发的,白色
//        [self.textView setBackgroundImage:[UIImage resizableImage1:@"msg_receive"] forState:UIControlStateNormal];
//        [self.textView setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        [self.textView setContentEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
//    }
}

@end
