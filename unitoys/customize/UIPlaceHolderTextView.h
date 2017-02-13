//
//  UIPlaceHolderTextView.h
//  mobileclient
//
//  Created by sumars on 15/12/27.
//  Copyright © 2015年 ququ-iOS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIPlaceHolderTextView : UITextView{
    
    NSString *placeholder;
    
    UIColor *placeholderColor;
    
    
    
@private
    
    UILabel *placeHolderLabel;
    
}



@property(nonatomic, retain) UILabel *placeHolderLabel;

@property(nonatomic, retain) NSString *placeholder;

@property(nonatomic, retain) UIColor *placeholderColor;



-(void)textChanged:(NSNotification*)notification;
@end
