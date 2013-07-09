//
//  HSQLColumnValue.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLColumnValue.h"

@implementation HSQLColumnValue

- (instancetype)initWithColumnIndex:(int)idx stmt:(sqlite3_stmt *)stmt
{
    NSParameterAssert(idx >= 0);
    NSParameterAssert(stmt);
    if ((self = [super init])) {
        _stmt = stmt;
        _idx = idx;
    }
    return self;
}

- (HSQLValueType)type
{
    return sqlite3_column_type(_stmt, _idx);
}

- (BOOL)isNull
{
    return sqlite3_column_type(_stmt, _idx) == SQLITE_NULL;
}

- (NSData *)blobValue
{
    const void *bytes = sqlite3_column_blob(_stmt, _idx);
    if (bytes) {
        NSUInteger length = sqlite3_column_bytes(_stmt, _idx);
        return [NSData dataWithBytes:bytes length:length];
    } else {
        return nil;
    }
}

- (double)doubleValue
{
    return sqlite3_column_double(_stmt, _idx);
}

- (int)intValue
{
    return sqlite3_column_int(_stmt, _idx);
}

- (sqlite3_int64)int64Value
{
    return sqlite3_column_int64(_stmt, _idx);
}

- (NSString *)stringValue
{
    const unsigned char *text = sqlite3_column_text(_stmt, _idx);
    if (text) {
        NSUInteger length = sqlite3_column_bytes(_stmt, _idx);
        return [[NSString alloc] initWithBytes:text length:length encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

@end
