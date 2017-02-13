//
//  LinkUsViewController.m
//  unitoys
//
//  Created by sumars on 16/9/22.
//  Copyright © 2016年 sumars. All rights reserved.
//

#import "LinkUsViewController.h"

@implementation LinkUsViewController

- (void) viewDidLoad {
    [super viewDidLoad];
}

#pragma mark 邮箱
- (IBAction)emailAction:(UIButton *)sender {
    
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    
    if (mailClass != nil) {
        
        // We must always check whether the current device is configured for sending emails
        //判断是否能调用邮箱客户端
        if ([mailClass canSendMail]) {
            [self displayComposerSheet];
        } else {
            [self launchMailAppOnDevice];
        }
    } else {
        [self launchMailAppOnDevice];
    }
}

// 1.  Launches the Mail application on the device.

-(void)launchMailAppOnDevice {
    NSString *recipients = [NSString stringWithFormat:@"mailto:%@&subject=对我想说的", EMAIL];
//    NSString *recipients = @"mailto:630893613@qq.com&subject=主题";
    NSString *body = @"&body=email body!";
    NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

// 2. Displays an email composition interface inside the application. Populates all the Mail fields.

-(void)displayComposerSheet {
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];/*MFMailComposeViewController邮件发送选择器*/
    picker.mailComposeDelegate = self;
    [picker setSubject:@"对我想说的"];/*emailpicker标题主题行*/
//    [mailPicker setToRecipients:[NSArray arrayWithObjects:EMAIL, nil]]; //设置发送给谁，参数是NSarray
//    cc
//    [mailPicker setCcRecipients:[NSArray arrayWithObject:@"zhuqil@163.com"]]; //可以添加抄送
//    bcc
//    [mailPicker setBccRecipients:[NSArray arrayWithObject:@"secret@gmail.com"]];
//    [mailPicker setMessageBody:@"反馈" isHTML:NO];     //邮件主题
//    NSData *imageData = UIImagePNGRepresentation(viewImage);//这里获取截图存入NSData，用于发送附件
//    [mailPicker addAttachmentData:imageData mimeType:@"image/png" fileName:@"WebScreenShot"];//发送附件的NSData，类型，附件名

    // Set up recipients
    NSArray *toRecipients = [NSArray arrayWithObject:EMAIL];
    [picker setToRecipients:toRecipients];
    
    NSLog(@"ios 应用发布后 .app 应用文件路径::%@",[NSBundle mainBundle] );
    NSLog(@"ios 应用发布后 .app 应用文件内 ::%@",[[NSBundle mainBundle] infoDictionary]);
    [picker setMessageBody:@"想说的话" isHTML:NO];
    [self presentModalViewController:picker animated:YES];
}


#pragma mark 代理方法
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
    switch (result){
        case MFMailComposeResultCancelled:
//            NSLog(@"取消发送了…");
            HUDNormal(@"已取消发送")
            break;
        case MFMailComposeResultSaved:
//            NSLog(@"邮件保存了…");
            HUDNormal(@"已保存")
            break;
        case MFMailComposeResultSent:
//            NSLog(@"邮件发送成功…");
            HUDNormal(@"发送成功")
            break;
        case MFMailComposeResultFailed:
            NSLog(@"邮件发送出错: %@…", [error localizedDescription]);
            HUDNormal([error localizedDescription])
            break;
        default:
            break;
    }
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark 电话
- (IBAction)callAction:(UIButton *)sender {
    //打电话的方法
    UIWebView *callWebView = [[UIWebView alloc] init];
    NSString *tel = [NSString stringWithFormat:@"tel:%@", TELEPHONE];
    NSURL *telURL = [NSURL URLWithString:tel];
    [callWebView loadRequest:[NSURLRequest requestWithURL:telURL]];
    [self.view addSubview:callWebView];
}



@end
