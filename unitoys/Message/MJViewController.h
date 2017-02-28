//
//  MJViewController.h
//  unitoys
//
//  Created by sumars on 16/10/27.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "BaseViewController.h"
#import "KTAutoHeightTextView.h"

@interface MJViewController : BaseViewController<UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnSend;
@property (weak, nonatomic) IBOutlet KTAutoHeightTextView *txtSendText;
@property (nonatomic, copy) NSString *toTelephone;
//@property (nonatomic, copy) NSString *toTelName;

- (IBAction)sendMessage:(id)sender;

@end
