//
//  HSQLValue.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, HSQLValueType) {
    HSQLValueTypeInteger = SQLITE_INTEGER,
    HSQLValueTypeFloat = SQLITE_FLOAT,
    HSQLValueTypeData = SQLITE_BLOB,
    HSQLValueTypeNull = SQLITE_NULL,
    HSQLValueTypeText = SQLITE3_TEXT
};

@protocol HSQLValue <NSObject>
- (HSQLValueType)type;
- (BOOL)isNull;
- (NSData *)dataValue;
- (double)doubleValue;
- (int)intValue;
- (sqlite3_int64)int64Value;
- (NSString *)stringValue;
@end
