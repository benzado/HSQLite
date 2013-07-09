//
//  HSQLDatabaseTests.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <HSQLite/HSQLite.h>

@interface HSQLDatabaseTests : XCTestCase

@end

@implementation HSQLDatabaseTests

- (void)testMemoryDatabase
{
    HSQLDatabase *db = [HSQLDatabase databaseInMemory];
    XCTAssertFalse([db isReadOnly]);
    XCTAssertEqualObjects(@"", [db absolutePath]);
    [db close];
}

- (void)testTemporaryDatabase
{
    HSQLDatabase *db = [HSQLDatabase databaseInMemory];
    XCTAssertFalse([db isReadOnly]);
    XCTAssertEqualObjects(@"", [db absolutePath]);
    [db close];
}

- (void)testNilQuery
{
    HSQLDatabase *db = [HSQLDatabase databaseInMemory];
    XCTAssertThrowsSpecificNamed([db statementWithQuery:nil error:NULL], NSException, NSInvalidArgumentException);
}

- (void)testEmptyQuery
{
    HSQLDatabase *db = [HSQLDatabase databaseInMemory];
    NSError *error = nil;
    HSQLStatement *st = [db statementWithQuery:@"" error:&error];
    XCTAssertNil(st);
    XCTAssertNotNil(error);
}

- (void)testConstantQuery
{
    HSQLDatabase *db = [HSQLDatabase databaseInMemory];
    NSError *error = nil;
    HSQLStatement *st = [db statementWithQuery:@"SELECT 42" error:&error];
    XCTAssertNotNil(st);
    XCTAssertNil(error);
}

- (void)testBadTableQuery
{
    HSQLDatabase *db = [HSQLDatabase databaseInMemory];
    NSError *error = nil;
    HSQLStatement *st = [db statementWithQuery:@"SELECT * FROM `badtable`" error:&error];
    XCTAssertNil(st);
    XCTAssertNotNil(error);
}

- (void)testCreateTable
{
    HSQLDatabase *db = [HSQLDatabase databaseInMemory];
    NSError *error = nil;
    [db executeQuery:(@"CREATE TABLE `people` ("
                      @"  `id` INTEGER PRIMARY KEY,"
                      @"  `name` TEXT NOT NULL,"
                      @"  `height` FLOAT)"
                      ) error:&error];
    XCTAssertNil(error);
}

- (void)testAppID
{
    HSQLDatabase *db = [HSQLDatabase databaseInMemory];
    XCTAssertEquals(0u, db.applicationID);
    db.applicationID = 'hsft';
#if SQLITE_VERSION_NUMBER < 3007017
    XCTAssertEquals(0u, db.applicationID);
#else
    XCTAssertEquals((uint32_t)'hsft', db.applicationID);
#endif
}

- (void)testUserVersion
{
    HSQLDatabase *db = [HSQLDatabase databaseInMemory];
    XCTAssertEquals(0, db.userVersion);
    db.userVersion = 42;
    XCTAssertEquals(42, db.userVersion);
    db.userVersion = -47;
    XCTAssertEquals(-47, db.userVersion);
}

@end
