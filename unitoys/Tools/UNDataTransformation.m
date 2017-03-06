//
//  UNDataTransformation.m
//  unitoys
//
//  Created by 黄磊 on 2017/3/4.
//  Copyright © 2017年 sumars. All rights reserved.
//

#import "UNDataTransformation.h"

@implementation UNDataTransformation

#pragma mark 将十六进制的数据包转换成byte数组
+ (NSData *)checkNewMessageReuseWithString:(NSString *)hexString {
    
    int len = (int)[hexString length] /2;// Target length
    
    unsigned char *buf = malloc(len);
    
    unsigned char *whole_byte = buf;
    
    char byte_chars[3] = {'\0','\0','\0'};
    
    int i;
    
    for (i=0; i < [hexString length] /2; i++) {
        
        byte_chars[0] = [hexString characterAtIndex:i*2];
        
        byte_chars[1] = [hexString characterAtIndex:i*2+1];
        
        *whole_byte = strtol(byte_chars, NULL, 16);
        
        whole_byte++;
        
    }
    
    NSData *data = [NSData dataWithBytes:buf length:len];
    
    free( buf );
    NSLog(@"最终发送的包 -> %@", data);
    return data;
}



@end
