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

@interface UCallPhonePadView()

@property (nonatomic, copy) NSArray *keyboardItems;

@property (nonatomic, strong) NSMutableArray *buttonArray;

@property (nonatomic, assign) NSInteger buttonCount;
@property (nonatomic, assign) NSInteger colCount;
@property (nonatomic, assign) NSInteger rowCount;
@property (nonatomic, assign) CGFloat margin;

@end

@implementation UCallPhonePadView

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
                               @"BottomTitle" : INTERNATIONALSTRING(@"全键盘"),
                               },
                           @{
                               @"TopTitle" : @"0",
                               @"BottomTitle" : @"+",
                               },
                           @{
                               @"TopTitle" : @"#",
                               @"BottomTitle" : INTERNATIONALSTRING(@"粘贴"),
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
    self.clipsToBounds = YES;
    self.backgroundColor = UIColorFromRGB(0xd2d2d2);
    
    _buttonCount = 12;
    _colCount = 3;
    _rowCount = 4;
    _margin = 1.0;
    
    self.buttonArray = [NSMutableArray arrayWithCapacity:_buttonCount];
    for (NSInteger i = 0; i < _buttonCount; i++) {
        NSDictionary *dict = self.keyboardItems[i];
        UCallPhoneButton *callButton = [UCallPhoneButton callPhoneButtonWithTopTitle:dict[@"TopTitle"] BottomTitle:dict[@"BottomTitle"] IsCanLongPress:NO];
        callButton.backgroundColor = [UIColor whiteColor];
        [callButton addTarget:self action:@selector(callButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.buttonArray addObject:callButton];
        [self addSubview:callButton];
    }
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
    }
    
    if (self.completeBlock) {
        self.completeBlock(btnSender.topTitle,btnSender.tag);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat buttonW = (CGFloat)(self.width - (_colCount - 1) * _margin) / _colCount;
    CGFloat buttonH = (CGFloat)(self.height - (_rowCount - 1) * _margin) / _rowCount;
    CGFloat buttonX;
    CGFloat buttonY;
    for (NSInteger i = 0; i < _buttonCount; i++) {
        buttonX = (i % _colCount) * (buttonW + _margin);
        buttonY = (i / _colCount) * (buttonH + _margin) + _margin;
        UCallPhoneButton * callButton = self.buttonArray[i];
        callButton.frame = CGRectMake(buttonX, buttonY, buttonW, buttonH);
    }
}

@end
