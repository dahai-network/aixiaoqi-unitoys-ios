//
//  UCallPhonePadView.m
//  unitoys
//
//  Created by 黄磊 on 2017/2/16.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UCallPhonePadView.h"
#import "UCallPhoneButton.h"
#import "UIView+Utils.h"
#import "global.h"

#define PhonePadHeight 225
#define PhoneLabelHeigth 70

@interface UCallPhonePadView()

@property (nonatomic, copy) NSArray *keyboardItems;

@property (nonatomic, strong) NSMutableArray *buttonArray;

@property (nonatomic, assign) NSInteger buttonCount;
@property (nonatomic, assign) NSInteger colCount;
@property (nonatomic, assign) NSInteger rowCount;
@property (nonatomic, assign) CGFloat margin;

//背景是否透明
@property (nonatomic, assign) BOOL isTransparent;

@end

@implementation UCallPhonePadView


+ (instancetype)callPhonePadViewWithFrame:(CGRect)frame IsTransparentBackground:(BOOL)isTransparent
{
    return [[UCallPhonePadView alloc] initWithFrame:frame IsTransparentBackground:isTransparent];
}

- (instancetype)initWithFrame:(CGRect)frame IsTransparentBackground:(BOOL)isTransparent
{
    _isTransparent = isTransparent;
    return [self initWithFrame:frame];
}

- (NSArray *)keyboardItems
{
    if (!_keyboardItems) {
        _keyboardItems = @[
                           @{
                               @"TopTitle" : @"1",
                               @"BottomTitle" : @"",
                            },
                           @{
                               @"TopTitle" : @"2",
                               @"BottomTitle" : @"ABC",
                             },
                           @{
                               @"TopTitle" : @"3",
                               @"BottomTitle" : @"DEF",
                               },
                           @{
                               @"TopTitle" : @"4",
                               @"BottomTitle" : @"GHI",
                               },
                           @{
                               @"TopTitle" : @"5",
                               @"BottomTitle" : @"JKL",
                               },
                           @{
                               @"TopTitle" : @"6",
                               @"BottomTitle" : @"MNO",
                               },
                           @{
                               @"TopTitle" : @"7",
                               @"BottomTitle" : @"PQRS",
                               },
                           @{
                               @"TopTitle" : @"8",
                               @"BottomTitle" : @"TUV",
                               },
                           @{
                               @"TopTitle" : @"9",
                               @"BottomTitle" : @"WXYZ",
                               },
                           @{
                               @"TopTitle" : @"*",
                               @"BottomTitle" : @"",
//                               @"BottomTitle" : INTERNATIONALSTRING(@"全键盘"),
                               },
                           @{
                               @"TopTitle" : @"0",
                               @"BottomTitle" : @"",
                               },
                           @{
                               @"TopTitle" : @"#",
                               @"BottomTitle" : @"",
//                               @"BottomTitle" : INTERNATIONALSTRING(@"粘贴"),
                               },
                           ];
    }
    return _keyboardItems;
}

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

//初始化子控件
- (void)initSubViews
{
    self.clipsToBounds = NO;
    if (self.isTransparent) {
        self.backgroundColor = [UIColor clearColor];
    }else{
        self.backgroundColor = UIColorFromRGB(0xe5e5e5);
    }
    
    
    _phoneNumLabel = [[UCallPhoneNumLabel alloc] initWithFrame:CGRectMake(0, - (PhoneLabelHeigth - 1), kScreenWidthValue, PhoneLabelHeigth - 1)];
    _phoneNumLabel.hidden = YES;
    kWeakSelf
    _phoneNumLabel.phoneLabelChangeBlock = ^(NSString *currentText, NSString *currentNum){
        weakSelf.inputedPhoneNumber = currentText;
        if (weakSelf.completeBlock) {
            weakSelf.completeBlock(currentText,currentNum);
        }
        if (!weakSelf.isHideDelLabel) {
            if (!currentText || !currentText.length) {
                weakSelf.phoneNumLabel.hidden = YES;
            }else{
                weakSelf.phoneNumLabel.hidden = NO;
            }
        }
    };
    [self addSubview:_phoneNumLabel];
    
    _buttonCount = 12;
    _colCount = 3;
    _rowCount = 4;
    _margin = 1.0;
    
    self.buttonArray = [NSMutableArray arrayWithCapacity:_buttonCount];
    UIColor *bgColor;
    if (_isTransparent) {
        bgColor = [UIColor clearColor];
    }else{
        bgColor = [UIColor whiteColor];
    }
    
    for (NSInteger i = 0; i < _buttonCount; i++) {
        NSDictionary *dict = self.keyboardItems[i];
//        BOOL isLongPress;
//        if ([dict[@"TopTitle"] isEqualToString:@"0"]) {
//            isLongPress = YES;
//        }else{
//            isLongPress = NO;
//        }
        UCallPhoneButton *callButton = [UCallPhoneButton callPhoneButtonWithTopTitle:dict[@"TopTitle"] BottomTitle:dict[@"BottomTitle"] IsCanLongPress:NO];
        callButton.isTransparent = _isTransparent;
//        callButton.phoneButtonLongPressAction = ^(NSString *topTitle, NSString *bottomTitle) {
//            NSString *sendchar = bottomTitle;
//            if (weakSelf.inputedPhoneNumber.length>0){
//                weakSelf.inputedPhoneNumber = [weakSelf.inputedPhoneNumber stringByAppendingString:sendchar];
//            }else{
//                weakSelf.inputedPhoneNumber = sendchar;
//            }
//            [weakSelf.phoneNumLabel updatePhoneLabel:weakSelf.inputedPhoneNumber currentNum:sendchar];
//        };
        callButton.backgroundColor = bgColor;
        [callButton addTarget:self action:@selector(callButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.buttonArray addObject:callButton];
        [self addSubview:callButton];
    }

//    if (_isTransparent) {
//        for (NSInteger i = 0; i < _buttonCount; i++) {
//            NSDictionary *dict = self.keyboardItems[i];
//            UCallPhoneButton *callButton = [UCallPhoneButton callPhoneButtonWithTopTitle:dict[@"TopTitle"] BottomTitle:dict[@"BottomTitle"] IsCanLongPress:NO];
//            callButton.isTransparent = YES;
//            callButton.backgroundColor = [UIColor clearColor];
//            [callButton addTarget:self action:@selector(callButtonAction:) forControlEvents:UIControlEventTouchUpInside];
//            [self.buttonArray addObject:callButton];
//            [self addSubview:callButton];
//        }
//    }else{
//        for (NSInteger i = 0; i < _buttonCount; i++) {
//            NSDictionary *dict = self.keyboardItems[i];
//            UCallPhoneButton *callButton = [UCallPhoneButton callPhoneButtonWithTopTitle:dict[@"TopTitle"] BottomTitle:dict[@"BottomTitle"] IsCanLongPress:NO];
//            callButton.backgroundColor = [UIColor whiteColor];
//            [callButton addTarget:self action:@selector(callButtonAction:) forControlEvents:UIControlEventTouchUpInside];
//            [self.buttonArray addObject:callButton];
//            [self addSubview:callButton];
//        }
//    }
}

- (void)callButtonAction:(UCallPhoneButton *)btnSender
{
    if (btnSender) {
        NSString *sendchar = btnSender.topTitle;
        if (self.inputedPhoneNumber.length>0){
            self.inputedPhoneNumber = [self.inputedPhoneNumber stringByAppendingString:sendchar];
        }else{
            self.inputedPhoneNumber = sendchar;
        }
        [_phoneNumLabel updatePhoneLabel:self.inputedPhoneNumber currentNum:sendchar];
    }
}

- (void)showCallView
{
    self.inputedPhoneNumber = @"";
    self.phoneNumLabel.phonelabel.text = @"";
    self.phoneNumLabel.hidden = NO;
}

- (void)hideCallView
{
    self.inputedPhoneNumber = @"";
    self.phoneNumLabel.phonelabel.text = @"";
    self.phoneNumLabel.hidden = YES;
}

- (void)showCallViewNoDelLabel
{
    self.inputedPhoneNumber = @"";
    self.phoneNumLabel.phonelabel.text = @"";
    self.isHideDelLabel = YES;
    self.phoneNumLabel.hidden = YES;
    self.hidden = NO;
}

- (void)hideCallViewNoDelLabel
{
    self.inputedPhoneNumber = @"";
    self.phoneNumLabel.phonelabel.text = @"";
    self.hidden = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat buttonW = (CGFloat)(self.un_width - (_colCount - 1) * _margin) / _colCount;
    CGFloat buttonH = (CGFloat)(self.un_height - 2 - (_rowCount - 1) * _margin) / _rowCount;
    CGFloat buttonX;
    CGFloat buttonY;
    for (NSInteger i = 0; i < _buttonCount; i++) {
        buttonX = (i % _colCount) * (buttonW + _margin);
        buttonY = (i / _colCount) * (buttonH + _margin) + _margin;
        UCallPhoneButton * callButton = self.buttonArray[i];
        callButton.frame = CGRectMake(buttonX, buttonY, buttonW, buttonH);
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        for (UIView *subView in self.subviews) {
            if ([subView isKindOfClass:[UCallPhoneNumLabel class]]) {
                if (!subView.isHidden) {
                    CGPoint p = [subView convertPoint:point fromView:self];
                    if (CGRectContainsPoint(subView.bounds, p)) {
                        view = subView;
                        for (UIView *subView2 in subView.subviews) {
                            CGPoint p2 = [subView2 convertPoint:p fromView:subView];
                            if (CGRectContainsPoint(subView2.bounds, p2)) {
                                view = subView2;
                            }
                        }
                    }
                }
            }
        }
    }
    return view;
}

@end
