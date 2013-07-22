//
//  HSQLTable.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLTable.h"
#import "HSQLStatement.h"
#import "HSQLRow.h"
#import "HSQLValue.h"

@interface HSQLTable ()
- (instancetype)initWithName:(NSString *)name database:(HSQLDatabase *)database;
@end

@implementation HSQLDatabase (Table)

- (HSQLTable *)tableNamed:(NSString *)name
{
    return [[HSQLTable alloc] initWithName:name database:self];
}

- (NSString *)masterTableName
{
    if ([self.name isEqualToString:@"temp"]) {
        return @"temp.sqlite_temp_master";
    } else {
        return [self.name stringByAppendingString:@".sqlite_master"];
    }
}

- (NSArray *)allTables
{
    NSString *query = [NSString stringWithFormat:
                       @"SELECT name FROM %@ WHERE type='table'",
                       [self masterTableName]];
    HSQLStatement *st = [self.session statementWithQuery:query error:nil];
    return [st arrayByExecutingWithBlock:^id(HSQLRow *row, BOOL *stop) {
        return [self tableNamed:[row[0] stringValue]];
    }];
}

@end

@implementation HSQLTable

- (instancetype)initWithName:(NSString *)name database:(HSQLDatabase *)database
{
    if ((self = [super init])) {
        _name = name;
        _database = database;
    }
    return self;
}

- (BOOL)exists
{
    NSString *query = [NSString stringWithFormat:
                       @"SELECT 1 FROM %@ WHERE type='table' AND name='%@'",
                       [self.database masterTableName], self.name];
    HSQLStatement *st = [self.database.session statementWithQuery:query error:nil];
    __block BOOL ret = NO;
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        ret = YES;
        *stop = YES;
    }];
    return ret;
}

- (NSString *)creationQuery
{
    NSString *query = [NSString stringWithFormat:
                       @"SELECT sql FROM %@ WHERE type='table' AND name='%@'",
                       [self.database masterTableName], self.name];
    HSQLStatement *st = [self.database.session statementWithQuery:query error:nil];
    __block NSString *sql = nil;
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        sql = [row[0] stringValue];
        *stop = YES;
    }];
    return sql;
}

- (NSUInteger)numberOfRows
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@.%@",
                       self.database.name, self.name];
    NSError *error = nil;
    HSQLStatement *st = [self.database.session statementWithQuery:query error:&error];
    if (error) {
        NSLog(@"error: numberOfRows %@", [error localizedDescription]);
    }
    __block NSUInteger count = NSNotFound;
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        count = [row[0] int64Value];
    }];
    return count;
}

@end
