//
//  HSQLSessionTests.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <HSQLite/HSQLite.h>

@interface HSQLSessionTests : XCTestCase

@end

@implementation HSQLSessionTests

- (void)testMemoryDatabase
{
    HSQLSession *db = [HSQLSession sessionWithMemoryDatabase];
    XCTAssertFalse([db isReadOnly]);
    XCTAssertEqualObjects(@"", [db absolutePath]);
    [db close];
}

- (void)testTemporaryDatabase
{
    HSQLSession *db = [HSQLSession sessionWithMemoryDatabase];
    XCTAssertFalse([db isReadOnly]);
    XCTAssertEqualObjects(@"", [db absolutePath]);
    [db close];
}

- (void)testNilQuery
{
    HSQLSession *db = [HSQLSession sessionWithMemoryDatabase];
    XCTAssertThrowsSpecificNamed([db statementWithQuery:nil error:NULL], NSException, NSInvalidArgumentException);
}

- (void)testEmptyQuery
{
    HSQLSession *db = [HSQLSession sessionWithMemoryDatabase];
    NSError *error = nil;
    HSQLStatement *st = [db statementWithQuery:@"" error:&error];
    XCTAssertNil(st);
    XCTAssertNotNil(error);
}

- (void)testConstantQuery
{
    HSQLSession *db = [HSQLSession sessionWithMemoryDatabase];
    NSError *error = nil;
    HSQLStatement *st = [db statementWithQuery:@"SELECT 42" error:&error];
    XCTAssertNotNil(st);
    XCTAssertNil(error);
}

- (void)testBadTableQuery
{
    HSQLSession *db = [HSQLSession sessionWithMemoryDatabase];
    NSError *error = nil;
    HSQLStatement *st = [db statementWithQuery:@"SELECT * FROM `badtable`" error:&error];
    XCTAssertNil(st);
    XCTAssertNotNil(error);
}

- (void)testCreateTable
{
    HSQLSession *db = [HSQLSession sessionWithMemoryDatabase];
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
    HSQLSession *db = [HSQLSession sessionWithMemoryDatabase];
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
    HSQLSession *db = [HSQLSession sessionWithMemoryDatabase];
    XCTAssertEquals(0, db.userVersion);
    db.userVersion = 42;
    XCTAssertEquals(42, db.userVersion);
    db.userVersion = -47;
    XCTAssertEquals(-47, db.userVersion);
}

@end
