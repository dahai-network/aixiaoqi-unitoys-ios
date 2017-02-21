//
//  FDCalendar.h
//  FDCalendarDemo
//
//  Created by fergusding on 15/8/20.
//  Copyright (c) 2015年 fergusding. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDCalendar : UIView

- (instancetype)initWithCurrentDate:(NSDate *)date;

- (instancetype)initWithCurrentDate:(NSDate *)date delegate:(id)delegate disableDate:(NSArray *)arrDisableDate;

@property (readwrite) NSDate *selectedDate;

@property (nonatomic) id delegate;

@property (readonly, nonatomic) UIWindow *bgWindow;

- (void)showCalendar;
- (void)hiddenCalendar;

- (void)removeWindow;

@end

@protocol FDCalendarDelegate <NSObject>
@optional
- (void)DidSelectDate:(NSDate *)date;

@end
