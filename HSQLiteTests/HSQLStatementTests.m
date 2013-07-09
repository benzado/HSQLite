//
//  HSQLStatementTests.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <HSQLite/HSQLite.h>

@interface HSQLStatementTests : XCTestCase
{
    HSQLDatabase *db;
}
@end

@implementation HSQLStatementTests

- (void)setUp
{
    [super setUp];
    db = [HSQLDatabase databaseInMemory];
}

- (void)tearDown
{
    [db close];
    [super tearDown];
}

- (void)testSelectNull
{
    HSQLStatement *st = [db statementWithQuery:@"SELECT NULL" error:NULL];
    XCTAssertNotNil(st);
    XCTAssertEquals(0, [st numberOfParameters]);
    XCTAssertEquals(1, [st numberOfColumns]);
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        id <HSQLValue> value = row[0];
        XCTAssertNotNil(value);
        XCTAssertTrue([value isNull]);
        XCTAssertEquals(HSQLValueTypeNull, [value type]);
        XCTAssertEquals(0, [value intValue]);
    }];
}

- (void)testSelectNumber
{
    HSQLStatement *st = [db statementWithQuery:@"SELECT 42" error:NULL];
    XCTAssertNotNil(st);
    XCTAssertEquals(0, [st numberOfParameters]);
    XCTAssertEquals(1, [st numberOfColumns]);
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        id <HSQLValue> value = row[0];
        XCTAssertNotNil(value);
        XCTAssertFalse([value isNull]);
        XCTAssertEquals(HSQLValueTypeInteger, [value type]);
        XCTAssertEquals(42, [value intValue]);
    }];
}

- (void)testSelectText
{
    HSQLStatement *st = [db statementWithQuery:@"SELECT \"Hello\", \"World\"" error:NULL];
    XCTAssertNotNil(st);
    XCTAssertEquals(0, [st numberOfParameters]);
    XCTAssertEquals(2, [st numberOfColumns]);
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        id <HSQLValue> value1 = row[0];
        XCTAssertNotNil(value1);
        XCTAssertFalse([value1 isNull]);
        XCTAssertEquals(HSQLValueTypeText, [value1 type]);
        XCTAssertEqualObjects(@"Hello", [value1 stringValue]);
        id <HSQLValue> value2 = row[1];
        XCTAssertNotNil(value2);
        XCTAssertFalse([value2 isNull]);
        XCTAssertEquals(HSQLValueTypeText, [value2 type]);
        XCTAssertEqualObjects(@"World", [value2 stringValue]);
    }];
}

- (void)testSelectFloat
{
    HSQLStatement *st = [db statementWithQuery:@"SELECT 3.141592653589793 AS `π`" error:NULL];
    XCTAssertNotNil(st);
    XCTAssertEquals(0, [st numberOfParameters]);
    XCTAssertEquals(1, [st numberOfColumns]);
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        id <HSQLValue> value = row[0];
        XCTAssertNotNil(value);
        XCTAssertFalse([value isNull]);
        XCTAssertEquals(HSQLValueTypeFloat, [value type]);
        XCTAssertEqualsWithAccuracy(3.141592653589793, [value doubleValue], 1e-15);
        value = row[@"π"];
        XCTAssertNotNil(value);
        XCTAssertFalse([value isNull]);
        XCTAssertEquals(HSQLValueTypeFloat, [value type]);
        XCTAssertEqualsWithAccuracy(3.141592653589793, [value doubleValue], 1e-15);
    }];
}

- (void)testSelectRowName
{
    static const id nilkey = nil;

    HSQLStatement *st = [db statementWithQuery:@"SELECT 1 AS `A`, 2 AS `B`" error:NULL];
    XCTAssertNotNil(st);
    XCTAssertEquals(0, [st numberOfParameters]);
    XCTAssertEquals(2, [st numberOfColumns]);
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        XCTAssertNotNil(row[@"A"]);
        XCTAssertNotNil(row[@"B"]);
        XCTAssertThrows(row[@"C"]);
        XCTAssertThrows(row[nilkey]);
        XCTAssertNotNil(row[0]);
        XCTAssertNotNil(row[1]);
        XCTAssertThrows(row[2]);
        XCTAssertThrows(row[-1]);
    }];
}

@end