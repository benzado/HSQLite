//
//  HSQLExpiredValue.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 8/29/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLExpiredValue.h"

@implementation HSQLExpiredValue

- (void)raiseException
{
    [NSException raise:NSInternalInconsistencyException format:
     @"Attempt to access a HSQLite value object after it has been invalidated. "
     @"It is invalid to use an instance of HSQLValue outside of the scope it "
     @"it was provided to. Copy values you need into another variable to "
     @"persist them outside of that scope."];
}

- (HSQLValueType)type
{
    [self raiseException];
    return 0xDEADBEEF;
}

- (BOOL)isNull
{
    [self raiseException];
    return NO;
}

- (NSData *)dataValue
{
    [self raiseException];
    return nil;
}

- (double)doubleValue
{
    [self raiseException];
    return 0;
}

- (int)intValue
{
    [self raiseException];
    return 0xDECAFBAD;
}

- (sqlite3_int64)int64Value
{
    [self raiseException];
    return 0xC0FFEE11;
}

- (NSString *)stringValue
{
    [self raiseException];
    return nil;
}

@end
