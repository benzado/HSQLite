//
//  HSQLParameterValue.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLParameterValue.h"

@implementation HSQLParameterValue

- (instancetype)initWithValue:(sqlite3_value *)value
{
    if ((self = [super init])) {
        _value = value;
    }
    return self;
}

- (HSQLValueType)type
{
    return sqlite3_value_type(_value);
}

- (BOOL)isNull
{
    return sqlite3_value_type(_value) == SQLITE_NULL;
}

- (NSData *)dataValue
{
    const void *bytes = sqlite3_value_blob(_value);
    if (bytes) {
        NSUInteger length = sqlite3_value_bytes(_value);
        return [NSData dataWithBytes:bytes length:length];
    } else {
        return nil;
    }
}

- (double)doubleValue
{
    return sqlite3_value_double(_value);
}

- (int)intValue
{
    return sqlite3_value_int(_value);
}

- (sqlite3_int64)int64Value
{
    return sqlite3_value_int64(_value);
}

- (NSString *)stringValue
{
    const void *bytes = sqlite3_value_text(_value);
    if (bytes) {
        NSUInteger length = sqlite3_value_bytes(_value);
        return [[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

@end
