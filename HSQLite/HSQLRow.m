//
//  HSQLRow.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <objc/runtime.h>

#import "HSQLStatement.h"
#import "HSQLRow.h"
#import "HSQLRow+Private.h"
#import "HSQLColumnValue.h"

@implementation HSQLRow
{
    HSQLStatement *_statement;
    NSMutableArray *_values;
}

- (instancetype)initWithStatement:(HSQLStatement *)statement stmt:(sqlite3_stmt *)stmt
{
    if ((self = [super init])) {
        _statement = statement;
        _values = [[NSMutableArray alloc] initWithCapacity:[_statement numberOfColumns]];
        for (int i = 0; i < [_statement numberOfColumns]; i++) {
            [_values addObject:[[HSQLColumnValue alloc] initWithColumnIndex:i stmt:stmt]];
        }
    }
    return self;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    if (idx >= [_values count]) {
        [NSException raise:NSRangeException format:@"Column index %d out of range", idx];
    }
    return _values[idx];
}

- (id)objectForKeyedSubscript:(NSString *)key
{
    NSUInteger idx = [_statement indexForColumnName:key];
    return self[idx];
}

- (void)invalidate
{
    [_values makeObjectsPerformSelector:@selector(invalidate)];
    object_setClass(self, [HSQLInvalidRow class]);
}

@end

@implementation HSQLInvalidRow

- (void)raiseException
{
    [NSException raise:NSInternalInconsistencyException format:
     @"Attempt to access a HSQLRow object after it has been invalidated. "
     @"It is invalid to use an instance of HSQLRow outside of the block it "
     @"it was provided to. Copy values you need into another variable to "
     @"persist them outside of the block."];
}

- (id<HSQLValue>)objectAtIndexedSubscript:(NSUInteger)idx
{
    [self raiseException];
    return nil;
}

- (id<HSQLValue>)objectForKeyedSubscript:(NSString *)key
{
    [self raiseException];
    return nil;
}

@end
