//
//  HSQLBackupTests.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/9/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <HSQLite/HSQLite.h>

@interface HSQLBackupTests : XCTestCase
{
    HSQLDatabase *sourceDatabase;
    NSUInteger rowsToCopy;
}
@end

@implementation HSQLBackupTests

- (void)setUp
{
    [super setUp];
    HSQLSession *session = [HSQLSession sessionWithTemporaryFile];
    [session executeQuery:@"CREATE TABLE foo ( bar ); INSERT INTO foo VALUES (random());" error:nil];
    HSQLStatement *stmt = [session statementWithQuery:@"INSERT INTO foo SELECT random() FROM foo" error:nil];
    for (int i = 0; i < 19; i++) {
        [stmt execute];
    }
    sourceDatabase = [session mainDatabase];
    rowsToCopy = [[sourceDatabase tableNamed:@"foo"] numberOfRows];
    XCTAssertTrue(rowsToCopy > 0);
    XCTAssertTrue([[sourceDatabase tableNamed:@"foo"] exists]);
    XCTAssertFalse([[sourceDatabase tableNamed:@"bar"] exists]);
}

- (void)tearDown
{
    sourceDatabase = nil;
    [super tearDown];
}

- (void)testSameSession
{
    NSError *error = nil;
    [sourceDatabase.session attachDatabaseFileAtPath:@"" forName:@"grue" error:nil];
    XCTAssertNil(error);
    HSQLDatabase *destDatabase = [sourceDatabase.session databaseNamed:@"grue"];
    HSQLBackupOperation *backup = [sourceDatabase backupOperationWithDestinationDatabase:destDatabase error:&error];
    XCTAssertNil(backup);
    XCTAssertNotNil(error);
}

- (void)testSameDatabase
{
    NSError *error = nil;
    HSQLBackupOperation *backup = [sourceDatabase backupOperationWithDestinationDatabase:sourceDatabase error:&error];
    XCTAssertNil(backup);
    XCTAssertNotNil(error);
}

- (void)testCopy
{
    HSQLDatabase *destDatabase = [[HSQLSession sessionWithTemporaryFile] mainDatabase];
    HSQLBackupOperation *backup = [sourceDatabase backupOperationWithDestinationDatabase:destDatabase error:nil];
    XCTAssertNotNil(backup);
    backup.progressBlock = ^(HSQLBackupOperation *backup) {
        NSLog(@"Progress: %f%% remaining %d/%d", 100 * backup.progress, backup.remainingNumberOfPages, backup.totalNumberOfPages);
    };
    NSError *error = nil;
    [backup start];
    XCTAssertTrue([backup isFinished]);
    XCTAssertNil(error);
    XCTAssertEqual(1.0f, backup.progress);
    HSQLTable *destTable = [destDatabase tableNamed:@"foo"];
    XCTAssertTrue([destTable exists]);
    XCTAssertEqual(rowsToCopy, [destTable numberOfRows]);
}

- (void)testCopyOnQueue
{
    HSQLDatabase *destDatabase = [[HSQLSession sessionWithTemporaryFile] mainDatabase];
    HSQLBackupOperation *backup = [sourceDatabase backupOperationWithDestinationDatabase:destDatabase error:nil];
    XCTAssertNotNil(backup);
    backup.progressBlock = ^(HSQLBackupOperation *backup) {
        NSLog(@"Progress: %f%% remaining %d/%d", 100 * backup.progress, backup.remainingNumberOfPages, backup.totalNumberOfPages);
    };
    NSOperationQueue *q = [[NSOperationQueue alloc] init];
    [q addOperation:backup];
    [q waitUntilAllOperationsAreFinished];
    XCTAssertEqual(1.0f, backup.progress);
    HSQLTable *destTable = [destDatabase tableNamed:@"foo"];
    XCTAssertTrue([destTable exists]);
    XCTAssertEqual(rowsToCopy, [destTable numberOfRows]);
}

@end
