//
//  HSQLDatabaseTests.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/21/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <HSQLite/HSQLite.h>

@interface HSQLDatabaseTests : XCTestCase
{
    HSQLSession *session;
}
@end

@implementation HSQLDatabaseTests

- (void)setUp
{
    [super setUp];
    session = [HSQLSession sessionWithMemoryDatabase];
}

- (void)tearDown
{
    [session close];
    [super tearDown];
}

- (void)testListDatabases
{
    XCTAssertEqual((NSUInteger)1, [[session allDatabases] count]);
    [session executeQuery:@"CREATE TEMPORARY TABLE foo (bar)" error:nil];
    XCTAssertEqual((NSUInteger)2, [[session allDatabases] count]);
    [session attachDatabaseFileAtPath:@":memory:" forName:@"grue" error:nil];
    XCTAssertEqual((NSUInteger)3, [[session allDatabases] count]);
}

- (void)testReadOnly
{
    XCTAssertFalse([[session mainDatabase] isReadOnly]);
    XCTAssertFalse([[session tempDatabase] isReadOnly]);
    XCTAssertFalse([[session databaseNamed:@"bogus"] isReadOnly]);
}

- (void)testTables
{
    [session executeQuery:@"CREATE TEMPORARY TABLE foo (bar)" error:nil];
    [session executeQuery:@"CREATE TABLE bat (man)" error:nil];
    XCTAssertFalse([[[session mainDatabase] tableNamed:@"foo"] exists]);
    XCTAssertTrue([[[session mainDatabase] tableNamed:@"bat"] exists]);
    XCTAssertTrue([[[session tempDatabase] tableNamed:@"foo"] exists]);
    XCTAssertFalse([[[session tempDatabase] tableNamed:@"bat"] exists]);
}

@end
