//
//  HSQLSession+Functions.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <HSQLite/HSQLDatabase.h>

@class HSQLFunctionContext;

typedef void(^HSQLScalarFunction)(HSQLFunctionContext *context);

@protocol HSQLAggregateFunction <NSObject>
+ (NSString *)name;
+ (int)numberOfArguments;
- (void)performStepWithContext:(HSQLFunctionContext *)context;
- (void)computeResultWithContext:(HSQLFunctionContext *)context;
@end

#define HSQLFunctionVariableArgumentCount -1

@interface HSQLSession (Functions)
- (void)defineScalarFunctionWithName:(NSString *)name numberOfArguments:(int)nArg block:(HSQLScalarFunction)block;
- (void)defineAggregateFunction:(Class)aggregateFunctionClass;
@end
