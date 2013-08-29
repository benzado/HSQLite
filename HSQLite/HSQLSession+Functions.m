//
//  HSQLSession+Functions.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLSession+Functions.h"
#import "HSQLFunctionContext.h"
#import "HSQLFunctionContext+Private.h"

void HSQLFunctionCallback(sqlite3_context *context, int argc, sqlite3_value **argv)
{
    HSQLScalarFunction func = (__bridge HSQLScalarFunction)sqlite3_user_data(context);
    HSQLFunctionContext *fc = [[HSQLFunctionContext alloc] initWithContext:context arguments:argv count:argc];
    func(fc);
    if ( ! [fc didReturn]) {
        [NSException raise:NSInternalInconsistencyException format:@"User-defined function did not return a value!"];
    }
    [fc invalidate];
}

void HSQLFunctionStep(sqlite3_context *context, int argc, sqlite3_value **argv)
{
    const void **ptr = sqlite3_aggregate_context(context, sizeof(void **));
    id <HSQLAggregateFunction> function;
    if (*ptr) {
        function = (__bridge id)(*ptr);
    } else {
        Class functionClass = (__bridge Class)sqlite3_user_data(context);
        function = [[functionClass alloc] init];
        *ptr = CFBridgingRetain(function);
    }
    HSQLFunctionContext *fc = [[HSQLFunctionContext alloc] initWithContext:context arguments:argv count:argc];
    [function performStepWithContext:fc];
    [fc invalidate];
}

void HSQLFunctionFinal(sqlite3_context *context)
{
    const void **ptr = sqlite3_aggregate_context(context, 0);
    id <HSQLAggregateFunction> function;
    if (ptr) {
        function = CFBridgingRelease(*ptr);
    } else {
        Class functionClass = (__bridge Class)sqlite3_user_data(context);
        function = [[functionClass alloc] init];
    }
    HSQLFunctionContext *fc = [[HSQLFunctionContext alloc] initWithContext:context arguments:NULL count:0];
    [function computeResultWithContext:fc];
    [fc invalidate];
}

void HSQLFunctionDestroy(void *ptr)
{
    CFRelease(ptr);
}

@implementation HSQLSession (Functions)

- (void)defineScalarFunctionWithName:(NSString *)name numberOfArguments:(int)nArg block:(HSQLScalarFunction)block
{
    void *ptr = (void *)CFBridgingRetain([block copy]);
    sqlite3_create_function_v2(_db,
                               [name UTF8String],
                               nArg,
                               SQLITE_UTF8,
                               ptr,
                               HSQLFunctionCallback,
                               NULL,
                               NULL,
                               HSQLFunctionDestroy);
}

- (void)defineAggregateFunction:(Class)aggregateFunctionClass
{
    if ( ! [aggregateFunctionClass conformsToProtocol:@protocol(HSQLAggregateFunction)]) {
        [NSException raise:NSInternalInconsistencyException format:
         @"Your aggregate function class %@ does not conform to protocol "
         @"HSQLAggregateFunction", NSStringFromClass(aggregateFunctionClass)];
    }
    void *ptr = (void *)CFBridgingRetain(aggregateFunctionClass);
    sqlite3_create_function_v2(_db,
                               [[aggregateFunctionClass name] UTF8String],
                               [aggregateFunctionClass numberOfArguments],
                               SQLITE_UTF8,
                               ptr,
                               NULL,
                               HSQLFunctionStep,
                               HSQLFunctionFinal,
                               HSQLFunctionDestroy);
}

@end
