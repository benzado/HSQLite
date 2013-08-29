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
    [db defineScalarFunctionWithName:@"FOO" numberOfArguments:0 block:^(HSQLFunctionContext *context) {
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
    [db defineScalarFunctionWithName:@"SIN" numberOfArguments:1 block:^(HSQLFunctionContext *context) {
        id <HSQLValue> arg = [context argumentValueAtIndex:0];
        [context returnDouble:sin([arg doubleValue])];
    }];
    [db defineScalarFunctionWithName:@"COS" numberOfArguments:1 block:^(HSQLFunctionContext *context) {
        id <HSQLValue> arg = context[0];
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
    [db defineScalarFunctionWithName:@"SIN" numberOfArguments:1 block:^(HSQLFunctionContext *context) {
        id cachedResult = [context auxiliaryObjectForArgumentAtIndex:0];
        if (cachedResult) {
            cacheHitCount += 1;
            [context returnDouble:[cachedResult doubleValue]];
        } else {
            cacheMissCount += 1;
            id <HSQLValue> arg = context[0];
            double a = sin([arg doubleValue]);
            [context setAuxiliaryObject:@(a) forArgumentAtIndex:0];
            [context returnDouble:a];
        }
    }];
    HSQLStatement *st = [db statementWithQuery:@"SELECT SIN(0)" error:NULL];
    [st execute];
    XCTAssertEqual(0, cacheHitCount);
    XCTAssertEqual(1, cacheMissCount);
    [st execute];
    XCTAssertEqual(1, cacheHitCount);
    XCTAssertEqual(1, cacheMissCount);
    [st execute];
    XCTAssertEqual(2, cacheHitCount);
    XCTAssertEqual(1, cacheMissCount);
}

- (void)testNoReturn
{
    [db defineScalarFunctionWithName:@"VAGUE" numberOfArguments:0 block:^(HSQLFunctionContext *context) {
        // do nothing
    }];
    HSQLStatement *st = [db statementWithQuery:@"SELECT VAGUE()" error:NULL];
    XCTAssertThrows([st execute]);
}

- (void)testValueEscape
{
    __block id savedContext;
    __block id savedValue;
    [db defineScalarFunctionWithName:@"WHAT" numberOfArguments:1 block:^(HSQLFunctionContext *context) {
        savedContext = context;
        savedValue = context[0];
        XCTAssertEqual(99, [savedValue intValue]);
        [context returnNull];
    }];
    HSQLStatement *st = [db statementWithQuery:@"SELECT WHAT(99)" error:NULL];
    [st execute];
    XCTAssertNotNil(savedContext);
    XCTAssertThrows(savedContext[0]);
    XCTAssertNotNil(savedValue);
    XCTAssertThrows([savedValue intValue]);
}

@end
