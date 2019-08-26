//
// Created by 刘伟 on 2019/8/26.
//

#import "ContactModel.h"

@implementation ContactModel

- (instancetype)initWithName:(NSString *)name
                 phoneNumber:(NSString *)phoneNumber
                 firstLetter:(NSString *)firstLetter{
    if (self = [super init]) {
        _name = name;
        _phoneNumber = phoneNumber;
        _firstLetter = firstLetter;
    }
    return self;
}

- (NSString *)phoneNumber{
    if (_phoneNumber == nil) {
        return @"";
    }
    return _phoneNumber;
}

- (NSString *)name{
    if (_name == nil) {
        return @"";
    }
    [_name stringByReplacingOccurrencesOfString:@"-" withString:@""];
    return _name;
}

- (NSString *)firstLetter{
    if (_firstLetter == nil) {
        return @"";
    }
    return _firstLetter;
}

@end