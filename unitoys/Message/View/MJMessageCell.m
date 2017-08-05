//
//  MJMessageCell.m
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "MJMessageCell.h"
//#import "MJMessageFrame.h"
//#import "MJMessage.h"
#import "UNMessageFrameModel.h"

#import "UIImage+Extension.h"
#import "global.h"
#import "UIView+Utils.h"
#import "UNRichLabel.h"

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
 *  正在加载
 */
@property (nonatomic, weak) UIActivityIndicatorView *indicatorView;
/**
 *  发送失败
 */
@property (nonatomic, weak) UIButton *failedbutton;

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
        timeView.textColor = UIColorFromRGB(0x999999);
        timeView.font = [UIFont systemFontOfSize:14];
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
        
        UNRichLabel *contentLabel = [[UNRichLabel alloc] init];
        self.contentLabel = contentLabel;
        contentLabel.userInteractionEnabled = YES;
        contentLabel.font = MJTextFont;
        contentLabel.numberOfLines = 0;
        contentLabel.lineBreakMode = NSLineBreakByCharWrapping;
        [containerView addSubview:contentLabel];
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] init];
        indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [indicatorView sizeToFit];
//        indicatorView.centerY = self.containerView.centerY;
//        indicatorView.right = self.containerView.left - 5;
        self.indicatorView = indicatorView;
//        [indicatorView startAnimating];
        [self.contentView addSubview:indicatorView];
        
        //发送失败
        UIButton *failedButton = [[UIButton alloc] init];
        [failedButton setImage:[UIImage imageNamed:@"sendMessage_faild"] forState:UIControlStateNormal];
        [failedButton sizeToFit];
        [failedButton addTarget:self action:@selector(repeatSendMessage:) forControlEvents:UIControlEventTouchUpInside];
        failedButton.enabled = NO;
        self.failedbutton = failedButton;
        [self.contentView addSubview:failedButton];
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
            _longPressCellBlock(self.tag, weakSelf.contentLabel.text, weakSelf.containerView);
        }
    }
}

- (void)setMessageFrame:(UNMessageFrameModel *)messageFrame
{
    _messageFrame = messageFrame;
    
//    MJMessage *message = messageFrame.message;
    UNMessageModel *message = messageFrame.message;
    
    // 1.时间
    self.timeView.frame = messageFrame.timeF;
    self.timeView.text = message.SMSTime;
    
    self.containerView.frame = messageFrame.containerViewF;
    self.bgImageView.frame = self.containerView.bounds;
    self.contentLabel.frame = CGRectMake(messageFrame.contentEdge.left, messageFrame.contentEdge.top, messageFrame.containerViewF.size.width - messageFrame.contentEdge.left - messageFrame.contentEdge.right, messageFrame.containerViewF.size.height - messageFrame.contentEdge.top - messageFrame.contentEdge.bottom);
    
    if (message.type == MJMessageTypeMe) {
//        self.bgImageView.tintColor = DefultColor;
//        [self.bgImageView setImage:[UIImage resizableImage:@"msg_send_new"]];
        [self.bgImageView setImage:[UIImage resizableImage:@"pic_sms"]];
        [self.contentLabel setTextColor:[UIColor whiteColor]];
        switch (message.Status) {
            case MJMessageStatuProcessing:
            {
                if (!self.failedbutton.isHidden) {
                    self.failedbutton.hidden = YES;
                    self.failedbutton.enabled = NO;
                }
                self.indicatorView.un_centerY = self.containerView.un_centerY;
                self.indicatorView.un_right = self.containerView.un_left - 5;
                self.indicatorView.hidden = NO;
                [self.indicatorView startAnimating];
            }
                break;
            case MJMessageStatuError:
            {
                if (!self.indicatorView.isHidden) {
                    self.indicatorView.hidden = YES;
                    [self.indicatorView stopAnimating];
                }
                self.failedbutton.un_centerY = self.containerView.un_centerY;
                self.failedbutton.un_right = self.containerView.un_left - 5;
                self.failedbutton.hidden = NO;
                self.failedbutton.enabled = YES;
            }

                break;
            default:
                //发送成功
                if (!self.indicatorView.isHidden) {
                    [self.indicatorView stopAnimating];
                    self.indicatorView.hidden = YES;
                }
                if (!self.failedbutton.isHidden) {
                    self.failedbutton.hidden = YES;
                    self.failedbutton.enabled = NO;
                }
                break;
        }
    }else{
        //发送成功
        if (!self.indicatorView.isHidden) {
            [self.indicatorView stopAnimating];
            self.indicatorView.hidden = YES;
        }
        if (!self.failedbutton.isHidden) {
            self.failedbutton.enabled = NO;
            self.failedbutton.hidden = YES;
        }
//        [self.bgImageView setImage:[UIImage resizableImage1:@"msg_receive_new"]];
        [self.bgImageView setImage:[UIImage resizableImage:@"pic_sms_a"]];
        [self.contentLabel setTextColor:UIColorFromRGB(0x333333)];
    }
    self.contentLabel.text = message.SMSContent;
    
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

//重发短信
- (void)repeatSendMessage:(UIButton *)button
{
    button.enabled = NO;
    if (_repeatSendMessageBlock) {
        _repeatSendMessageBlock(_messageFrame);
    }
}

@end
