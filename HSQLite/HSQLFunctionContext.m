//
//  HSQLFunctionContext.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLFunctionContext.h"

void HSQLFunctionContextDestroyAuxiliaryObject(void *ptr)
{
    CFBridgingRelease(ptr);
}

@implementation HSQLFunctionContext

- (instancetype)initWithContext:(sqlite3_context *)context
{
    if ((self = [super init])) {
        _context = context;
    }
    return self;
}

- (void)returnData:(NSData *)result
{
    sqlite3_result_blob(_context, [result bytes], [result length], SQLITE_TRANSIENT);
}

- (void)returnDouble:(double)result
{
    sqlite3_result_double(_context, result);
}

- (void)returnInt:(int)result
{
    sqlite3_result_int(_context, result);
}

- (void)returnInt64:(sqlite3_int64)result
{
    sqlite3_result_int64(_context, result);
}

- (void)returnNull
{
    sqlite3_result_null(_context);
}

- (void)returnString:(NSString *)result
{
    sqlite3_result_text(_context, [result UTF8String], -1, SQLITE_TRANSIENT);
}

- (void)returnValue:(id <HSQLValue>)result
{
    [NSException raise:NSInternalInconsistencyException format:@"Not yet implemented"];
    sqlite3_result_value(_context, NULL);
}

- (void)returnErrorMessage:(NSString *)message
{
    sqlite3_result_error(_context, [message UTF8String], -1);
}

- (void)returnErrorTooBig
{
    sqlite3_result_error_toobig(_context);
}

- (void)returnErrorNoMemory
{
    sqlite3_result_error_nomem(_context);
}

- (void)returnErrorCode:(int)code
{
    sqlite3_result_error_code(_context, code);
}

- (id)auxiliaryObjectForArgumentAtIndex:(int)idx
{
    return (__bridge id)(sqlite3_get_auxdata(_context, idx));
}

- (void)setAuxiliaryObject:(id)object forArgumentAtIndex:(int)idx
{
    void *ptr = (void *)CFBridgingRetain(object);
    sqlite3_set_auxdata(_context, idx, ptr, &HSQLFunctionContextDestroyAuxiliaryObject);
}

@end

@implementation HSQLAggregateFunctionContext

- (id)aggregateContextObjectIfPresent
{
    const void **ptr = sqlite3_aggregate_context(_context, 0);
    if (ptr) {
        return (__bridge id)(ptr[1]);
    } else {
        return nil;
    }
}

- (id)aggregateContextObject
{
    const void **ptr = sqlite3_aggregate_context(_context, 2 * sizeof(void *));
    return (__bridge id)(ptr[1]);
}

- (void)setAggregateContextObject:(id)object
{
    const void **ptr = sqlite3_aggregate_context(_context, 2 * sizeof(void *));
    if (ptr[0] == _context && ptr[1] != NULL) {
        CFRelease(ptr[1]);
    }
    ptr[0] = _context;
    ptr[1] = CFBridgingRetain(object);
}

- (void)releaseAggregateContextObject
{
    const void **ptr = sqlite3_aggregate_context(_context, 0);
    if (ptr && ptr[0] == _context && ptr[1] != NULL) {
        CFRelease(ptr[1]);
        ptr[1] = NULL;
    }
}

- (void *)aggregateContextBytesIfPresent
{
    return sqlite3_aggregate_context(_context, 0);
}

- (void *)aggregateContextBytesOfLength:(NSUInteger)length
{
    return sqlite3_aggregate_context(_context, length);
}

@end
