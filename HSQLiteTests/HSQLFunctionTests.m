//
//  HSQLFunctionTests.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <HSQLite/HSQLite.h>

@interface HSQLFunctionTests : XCTestCase
{
    HSQLSession *db;
}
@end

@implementation HSQLFunctionTests

- (void)setUp
{
    [super setUp];
    db = [HSQLSession sessionWithMemoryDatabase];
}

- (void)tearDown
{
    [db close];
    [super tearDown];
}

- (void)testSimpleScalarFunction
{
    [db defineScalarFunction:@"FOO" numberOfArguments:0 block:^(HSQLFunctionContext *context, NSArray *arguments) {
        [context returnString:@"BAR"];
    }];
    NSError *error = nil;
    HSQLStatement *st = [db statementWithQuery:@"SELECT FOO()" error:&error];
    XCTAssertNotNil(st);
    XCTAssertNil(error);
    XCTAssertEqual(1, [st numberOfColumns]);
    XCTAssertEqual(0, [st numberOfParameters]);
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        XCTAssertEqualObjects(@"BAR", [row[0] stringValue]);
    }];
}

- (void)testTrigFunctions
{
    [db defineScalarFunction:@"SIN" numberOfArguments:1 block:^(HSQLFunctionContext *context, NSArray *arguments) {
        id <HSQLValue> arg = arguments[0];
        [context returnDouble:sin([arg doubleValue])];
    }];
    [db defineScalarFunction:@"COS" numberOfArguments:1 block:^(HSQLFunctionContext *context, NSArray *arguments) {
        id <HSQLValue> arg = arguments[0];
        [context returnDouble:cos([arg doubleValue])];
    }];
    NSError *error = nil;
    HSQLStatement *st = [db statementWithQuery:@"SELECT (SIN($u) * SIN($u)) + (COS(:v) * COS(:v))" error:&error];
    XCTAssertNotNil(st);
    XCTAssertNil(error);
    XCTAssertEqual(1, [st numberOfColumns]);
    XCTAssertEqual(2, [st numberOfParameters]);
    st[@"$u"] = @(M_PI_2);
    st[@":v"] = @(M_PI_2);
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        XCTAssertEqual(1.0, [row[0] doubleValue]);
    }];
}

- (void)testFunctionCache
{
    __block int cacheHitCount = 0;
    __block int cacheMissCount = 0;
    [db defineScalarFunction:@"SIN" numberOfArguments:1 block:^(HSQLFunctionContext *context, NSArray *arguments) {
        id cachedResult = [context auxiliaryObjectForArgumentAtIndex:0];
        if (cachedResult) {
            cacheHitCount += 1;
            [context returnDouble:[cachedResult doubleValue]];
        } else {
            cacheMissCount += 1;
            id <HSQLValue> arg = arguments[0];
            double a = sin([arg doubleValue]);
            [context setAuxiliaryObject:@(a) forArgumentAtIndex:0];
            [context returnDouble:a];
        }
    }];
    HSQLStatement *st = [db statementWithQuery:@"SELECT SIN(0)" error:NULL];
    [st executeWithBlock:NULL];
    XCTAssertEqual(0, cacheHitCount);
    XCTAssertEqual(1, cacheMissCount);
    [st executeWithBlock:NULL];
    XCTAssertEqual(1, cacheHitCount);
    XCTAssertEqual(1, cacheMissCount);
    [st executeWithBlock:NULL];
    XCTAssertEqual(2, cacheHitCount);
    XCTAssertEqual(1, cacheMissCount);
}

- (void)testAggregateFunction
{
    [db defineAggregateFunction:@"MEDIAN" numberOfArguments:1 block:^(HSQLAggregateFunctionContext *context, NSArray *arguments) {
        if (arguments) {
            id <HSQLValue> arg = arguments[0];
            if ( ! [arg isNull]) {
                NSMutableArray *array = [context aggregateContextObject];
                if (array == nil) {
                    array = [[NSMutableArray alloc] init];
                    [context setAggregateContextObject:array];
                }
                [array addObject:@([arg doubleValue])];
            }
        } else {
            NSMutableArray *array = [context aggregateContextObjectIfPresent];
            if ([array count] == 0) {
                [context returnNull];
            }
            else if ([array count] == 1) {
                [context returnDouble:[array[0] doubleValue]];
            }
            else {
                [array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    return [obj1 compare:obj2];
                }];
                NSInteger mid = [array count] / 2;
                if ([array count] % 2) {
                    NSNumber *median = [array objectAtIndex:mid];
                    [context returnDouble:[median doubleValue]];
                } else {
                    double a = [[array objectAtIndex:(mid - 1)] doubleValue];
                    double b = [[array objectAtIndex:(mid)] doubleValue];
                    [context returnDouble:((a + b) / 2.0)];
                }
            }
        }
    }];
    NSError *error = nil;
    {
        NSString *sql = (@"CREATE TABLE `numbers` (`n` REAL);"
                         @"INSERT INTO `numbers` (`n`) VALUES "
                         @"(1.5),(4.5),(NULL),(5.5),(8.5),(9.5),(NULL),"
                         @"(2.5),(3.5),(NULL),(6.5),(7.5),(NULL);");
        [db executeQuery:sql error:&error];
        XCTAssertNil(error);
    }
    HSQLStatement *st = [db statementWithQuery:@"SELECT MEDIAN(`n`) FROM `numbers` WHERE `n` < ?" error:&error];
    XCTAssertNotNil(st);
    XCTAssertNil(error);
    __block double median;
    
    st[1] = @(99);
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        median = [row[0] doubleValue];
    }];
    XCTAssertEqual(5.5, median);
    
    st[1] = @(5);
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        median = [row[0] doubleValue];
    }];
    XCTAssertEqual(3.0, median);
    
    st[1] = @(2);
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        median = [row[0] doubleValue];
    }];
    XCTAssertEqual(1.5, median);

    st[1] = @(0);
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        XCTAssertTrue([row[0] isNull]);
        median = [row[0] doubleValue];
    }];
    XCTAssertEqual(0.0, median);
}

@end
