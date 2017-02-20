//
//  NSString+Utils.m
//  WeChatContacts-demo
//
//  Created by shen_gh on 16/3/12.
//  Copyright © 2016年 com.joinup(Beijing). All rights reserved.
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

//汉字的拼音
- (NSString *)pinyin{
//    NSMutableString *str = [self mutableCopy];
//    CFStringTransform(( CFMutableStringRef)str, NULL, kCFStringTransformMandarinLatin, NO);
//    CFStringTransform((CFMutableStringRef)str, NULL, kCFStringTransformStripDiacritics, NO);
//    
//    return [[str stringByReplacingOccurrencesOfString:@"'" withString:@""] uppercaseString];
    if (self.length == 0) {
        return @"";
    }
    NSString *tempStr = [NSMutableString stringWithString:self];
    NSMutableString *spaceStr = [NSMutableString string];
    for (int i = 0; i < tempStr.length; i++) {
        NSString *str = [tempStr substringWithRange:NSMakeRange(i, 1)];
        [spaceStr appendString:str];
        [spaceStr appendString:@" "];
    }
    
    NSMutableString *mutableString = [NSMutableString stringWithString:spaceStr];
    CFStringTransform((CFMutableStringRef)mutableString, NULL, kCFStringTransformToLatin, false);
    mutableString = (NSMutableString *)[mutableString stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
    return [[mutableString stringByReplacingOccurrencesOfString:@"'" withString:@""] uppercaseString];
}

- (NSString *)removeSpace
{
    return [[[self copy] stringByReplacingOccurrencesOfString:@" " withString:@""] uppercaseString];
}

- (NSString *)pinyinHeader {
    
    NSString *pinyinStr = [NSString stringWithString:self];
    NSArray *array = [pinyinStr componentsSeparatedByString:@" "];
    NSMutableString *mutableString = [NSMutableString string];
    for (NSString *string in array) {
        if (string.length) {
            [mutableString appendString:[string substringToIndex:1]];
        }
    }
    return mutableString;
}

- (NSString *)pinyinToNumber
{
    NSString *pinyinStr = [self copy];
    NSMutableString *numberStr = [NSMutableString string];
    for (int i = 0; i < pinyinStr.length; i++) {
        NSString *str = [pinyinStr substringWithRange:NSMakeRange(i, 1)];
        unichar charStr = [str characterAtIndex:0];
        if ((charStr >= 65 && charStr <= 90) || (charStr >= 97 && charStr <=122)) {
            [numberStr appendString:[self charToNumber:charStr]];
        }else{
            [numberStr appendString:str];
        }
    }
    return numberStr;
}

- (NSString *)charToNumber:(unichar)charStr
{
    if (charStr >= 65 && charStr <= 67) {
        return @"2";
    }else if (charStr >= 68 && charStr <= 70){
        return @"3";
    }else if (charStr >= 71 && charStr <= 73){
        return @"4";
    }else if (charStr >= 74 && charStr <= 76){
        return @"5";
    }else if (charStr >= 77 && charStr <= 79){
        return @"6";
    }else if (charStr >= 80 && charStr <= 83){
        return @"7";
    }else if (charStr >= 84 && charStr <= 86){
        return @"8";
    }else if (charStr >= 87 && charStr <= 90){
        return @"9";
    }else{
        return @"0";
    }
}

//- (NSString *)pinyinHeader
//{
//    
//    NSMutableString *source = [self mutableCopy];
//    if(source && self.length>0)
//        
//    {
//        CFRange range = CFRangeMake(0, 1);
//        
//        CFStringTransform((__bridge CFMutableStringRef)source, &range, kCFStringTransformMandarinLatin, NO);
//        CFStringTransform((__bridge CFMutableStringRef)source, &range, kCFStringTransformStripDiacritics, NO);
//        NSString *phonetic = source;
//        phonetic = [phonetic substringToIndex:1];
//        phonetic = [phonetic uppercaseString];
//        int temp = [phonetic characterAtIndex:0];
//        if (temp < 65 || temp > 122 || (temp > 90 && temp < 97)) {
//            //不合法的title
//            phonetic = @"#";
//            
//        }else{
//            phonetic = phonetic;
//        }
//        return phonetic;
//    }else
//    {
//        return @"#";
//    }
//}

@end
