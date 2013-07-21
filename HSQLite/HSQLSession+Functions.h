//
//  HSQLSession+Functions.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLSession.h"

@class HSQLFunctionContext;
@class HSQLAggregateFunctionContext;

typedef void(^HSQLScalarFunction)(HSQLFunctionContext *context, NSArray *arguments);
typedef void(^HSQLAggregateFunction)(HSQLAggregateFunctionContext *context, NSArray *arguments);

#define HSQLFunctionVariableArgumentCount -1

@interface HSQLSession (Functions)
- (void)defineScalarFunction:(NSString *)name numberOfArguments:(int)nArg block:(HSQLScalarFunction)block;
- (void)defineAggregateFunction:(NSString *)name numberOfArguments:(int)nArg block:(HSQLAggregateFunction)block;
@end
