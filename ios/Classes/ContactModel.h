//
// Created by 刘伟 on 2019/8/26.
//

#import <Flutter/Flutter.h>

@interface ContactModel : NSObject

/// 姓名
@property (copy, nonatomic) NSString* name;

/// 联系方式
@property (copy, nonatomic) NSString* phoneNumber;

/// 首字母
@property (copy, nonatomic) NSString* firstLetter;

- (instancetype)initWithName:(NSString*)name
                 phoneNumber:(NSString*)phoneNumber
                 firstLetter:(NSString*)firstLetter;

@end
