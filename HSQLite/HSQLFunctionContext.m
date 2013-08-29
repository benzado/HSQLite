//
//  HSQLFunctionContext.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLFunctionContext.h"
#import "HSQLFunctionContext+Private.h"
#import "HSQLParameterValue.h"

void HSQLFunctionContextDestroyAuxiliaryObject(void *ptr)
{
    CFBridgingRelease(ptr);
}

@implementation HSQLFunctionContext
{
    sqlite3_context *_context;
    NSArray *_arguments;
    BOOL _didReturn;
}

- (instancetype)initWithContext:(sqlite3_context *)context arguments:(sqlite3_value **)argv count:(int)argc
{
    if ((self = [super init])) {
        _context = context;
        NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:argc];
        for (int i = 0; i < argc; i++) {
            HSQLParameterValue *value = [[HSQLParameterValue alloc] initWithValue:argv[i]];
            [arguments addObject:value];
        }
        _arguments = arguments;
    }
    return self;
}

- (void)invalidate
{
    [_arguments makeObjectsPerformSelector:@selector(invalidate)];
    _context = NULL;
    _arguments = nil;
}

- (BOOL)didReturn
{
    return _didReturn;
}

- (int)argumentCount
{
    if (_context == NULL) {
        [NSException raise:NSInternalInconsistencyException format:@"Illegal attempt to access HSQLFunctionContext outside of function scope."];
    }
    return [_arguments count];
}

- (id <HSQLValue>)argumentValueAtIndex:(int)idx
{
    if (_context == NULL) {
        [NSException raise:NSInternalInconsistencyException format:@"Illegal attempt to access HSQLFunctionContext outside of function scope."];
    }
    return _arguments[idx];
}

- (id <HSQLValue>)objectAtIndexedSubscript:(NSUInteger)idx
{
    return [self argumentValueAtIndex:idx];
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

- (void)returnData:(NSData *)result
{
    sqlite3_result_blob(_context, [result bytes], [result length], SQLITE_TRANSIENT);
    _didReturn = YES;
}

- (void)returnDouble:(double)result
{
    sqlite3_result_double(_context, result);
    _didReturn = YES;
}

- (void)returnInt:(int)result
{
    sqlite3_result_int(_context, result);
    _didReturn = YES;
}

- (void)returnInt64:(sqlite3_int64)result
{
    sqlite3_result_int64(_context, result);
    _didReturn = YES;
}

- (void)returnNull
{
    sqlite3_result_null(_context);
    _didReturn = YES;
}

- (void)returnString:(NSString *)result
{
    sqlite3_result_text(_context, [result UTF8String], -1, SQLITE_TRANSIENT);
    _didReturn = YES;
}

- (void)returnValue:(id <HSQLValue>)result
{
    [NSException raise:NSInternalInconsistencyException format:@"Not yet implemented"];
    // sqlite3_result_value(_context, ?);
    _didReturn = YES;
}

- (void)returnErrorMessage:(NSString *)message
{
    sqlite3_result_error(_context, [message UTF8String], -1);
    _didReturn = YES;
}

- (void)returnErrorTooBig
{
    sqlite3_result_error_toobig(_context);
    _didReturn = YES;
}

- (void)returnErrorNoMemory
{
    sqlite3_result_error_nomem(_context);
    _didReturn = YES;
}

- (void)returnErrorCode:(int)code
{
    sqlite3_result_error_code(_context, code);
    _didReturn = YES;
}

@end
