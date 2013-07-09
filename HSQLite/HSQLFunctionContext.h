//
//  HSQLFunctionContext.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HSQLValue;

@interface HSQLFunctionContext : NSObject
{
    sqlite3_context *_context;
}
- (void)returnData:(NSData *)result;
- (void)returnDouble:(double)result;
- (void)returnInt:(int)result;
- (void)returnInt64:(sqlite3_int64)result;
- (void)returnNull;
- (void)returnString:(NSString *)result;
- (void)returnValue:(id <HSQLValue>)result;
- (void)returnErrorMessage:(NSString *)message;
- (void)returnErrorTooBig;
- (void)returnErrorNoMemory;
- (void)returnErrorCode:(int)code;
// for caching responses
- (id)auxiliaryObjectForArgumentAtIndex:(int)idx;
- (void)setAuxiliaryObject:(id)object forArgumentAtIndex:(int)idx;
@end

@interface HSQLAggregateFunctionContext : HSQLFunctionContext
- (id)aggregateContextObjectIfPresent;
- (id)aggregateContextObject;
- (void)setAggregateContextObject:(id)object;
- (void *)aggregateContextBytesIfPresent;
- (void *)aggregateContextBytesOfLength:(NSUInteger)length;
@end
