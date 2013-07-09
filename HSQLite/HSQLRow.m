//
//  HSQLRow.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLStatement.h"
#import "HSQLRow.h"
#import "HSQLRow+Private.h"
#import "HSQLColumnValue.h"

@implementation HSQLRow

- (instancetype)initWithStatement:(HSQLStatement *)statement stmt:(sqlite3_stmt *)stmt
{
    if ((self = [super init])) {
        _statement = statement;
        _stmt = stmt;
    }
    return self;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    if (idx >= [_statement numberOfColumns]) {
        [NSException raise:NSRangeException format:@"Column index %d out of range", idx];
    }
    return [[HSQLColumnValue alloc] initWithColumnIndex:idx stmt:_stmt];
}

- (id)objectForKeyedSubscript:(NSString *)key
{
    NSUInteger idx = [_statement indexForColumnName:key];
    return self[idx];
}

@end
