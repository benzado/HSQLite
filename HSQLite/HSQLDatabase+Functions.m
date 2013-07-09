//
//  HSQLDatabase+Functions.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLDatabase+Functions.h"
#import "HSQLFunctionContext.h"
#import "HSQLParameterValue.h"
#import "HSQLFunctionContext+Private.h"

NSArray *HSQLFunctionArguments(int argc, sqlite3_value **argv)
{
    NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:argc];
    for (int i = 0; i < argc; i++) {
        HSQLParameterValue *value = [[HSQLParameterValue alloc] initWithValue:argv[i]];
        [arguments addObject:value];
    }
    return arguments;
}

void HSQLFunctionCallback(sqlite3_context *context, int argc, sqlite3_value **argv)
{
    HSQLScalarFunction func = (__bridge HSQLScalarFunction)sqlite3_user_data(context);
    HSQLFunctionContext *fc = [[HSQLFunctionContext alloc] initWithContext:context];
    NSArray *arguments = HSQLFunctionArguments(argc, argv);
    func(fc, arguments);
}

void HSQLFunctionStep(sqlite3_context *context, int argc, sqlite3_value **argv)
{
    HSQLAggregateFunction func = (__bridge HSQLAggregateFunction)sqlite3_user_data(context);
    HSQLAggregateFunctionContext *fc = [[HSQLAggregateFunctionContext alloc] initWithContext:context];
    NSArray *arguments = HSQLFunctionArguments(argc, argv);
    func(fc, arguments);
}

void HSQLFunctionFinal(sqlite3_context *context)
{
    HSQLAggregateFunction func = (__bridge HSQLAggregateFunction)sqlite3_user_data(context);
    HSQLAggregateFunctionContext *fc = [[HSQLAggregateFunctionContext alloc] initWithContext:context];
    func(fc, nil);
    [fc releaseAggregateContextObject];
}

void HSQLFunctionDestroy(void *ptr)
{
    CFRelease(ptr);
}

@implementation HSQLDatabase (Functions)

- (void)defineScalarFunction:(NSString *)name numberOfArguments:(int)nArg block:(HSQLScalarFunction)block
{
    void *ptr = (void *)CFBridgingRetain([block copy]);
    sqlite3_create_function_v2(_db, [name UTF8String], nArg, SQLITE_UTF8, ptr,
                               HSQLFunctionCallback,
                               NULL,
                               NULL,
                               HSQLFunctionDestroy);
}

- (void)defineAggregateFunction:(NSString *)name numberOfArguments:(int)nArg block:(HSQLAggregateFunction)block
{
    void *ptr = (void *)CFBridgingRetain([block copy]);
    sqlite3_create_function_v2(_db, [name UTF8String], nArg, SQLITE_UTF8, ptr,
                               NULL,
                               HSQLFunctionStep,
                               HSQLFunctionFinal,
                               HSQLFunctionDestroy);
}

@end
