//
//  PhonePadView.h
//  CloudEgg
//
//  Created by ququ-iOS on 16/2/19.
//  Copyright © 2016年 ququ-iOS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhonePadView : UIView
//@property (weak, nonatomic) IBOutlet UITextField *lblPhoneNumber;
//- IBAction)delPhoneStr:(id)sender;

- (IBAction)inputPhoneStr:(id)sender;


@property (strong,nonatomic) NSString *inputedPhoneNumber;


typedef void (^InputCompletedBlock)(NSString *btnText,NSInteger btnTag);
@property (nonatomic,copy)InputCompletedBlock completeBlock;


@end
