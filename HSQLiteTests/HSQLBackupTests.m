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
    HSQLSession *sourceDatabase;
}
@end

@implementation HSQLBackupTests

- (void)setUp
{
    [super setUp];
    sourceDatabase = [HSQLSession sessionWithMemoryDatabase];
    [sourceDatabase executeQuery:@"CREATE TABLE foo ( bar ); INSERT INTO foo VALUES (random());" error:nil];
    HSQLStatement *stmt = [sourceDatabase statementWithQuery:@"INSERT INTO foo SELECT random() FROM foo" error:nil];
    for (int i = 0; i < 19; i++) {
        [stmt executeWithBlock:NULL];
    }
}

- (void)tearDown
{
    sourceDatabase = nil;
    [super tearDown];
}

- (void)testCopy
{
    HSQLSession *destDatabase = [HSQLSession sessionWithMemoryDatabase];
    HSQLBackupSession *backup = [sourceDatabase backupSessionWithDestinationDatabase:destDatabase];
    XCTAssertNotNil(backup);
    NSError *error = nil;
    BOOL done = [backup copyAllRemainingPagesError:&error];
    XCTAssertTrue(done);
    XCTAssertNil(error);
    XCTAssertEquals(1.0f, backup.progress);
}

- (void)testPrematureWriteToDestination
{
    HSQLSession *destDatabase = [HSQLSession sessionWithMemoryDatabase];
    HSQLBackupSession *backup = [sourceDatabase backupSessionWithDestinationDatabase:destDatabase];
    XCTAssertNotNil(backup);
    NSError *error = nil;
    BOOL done = [backup copyPagesBatchOfSize:16 error:&error];
    XCTAssertFalse(done);
    XCTAssertNil(error);
    [destDatabase executeQuery:@"INSERT INTO foo VALUES (NULL)" error:&error];
    XCTAssertNotNil(error);
}

- (void)testCopyOnQueue
{
    HSQLSession *destDatabase = [HSQLSession sessionWithMemoryDatabase];
    HSQLBackupSession *backup = [sourceDatabase backupSessionWithDestinationDatabase:destDatabase];
    XCTAssertNotNil(backup);
    dispatch_queue_t q = dispatch_queue_create("test", NULL);
    __block BOOL isComplete = NO;
    [backup setProgressNotificationInterval:0.01];
    [backup copyPagesOnQueue:q progressHandler:^{
        NSLog(@"Progress: %f%% remaining %d/%d", 100 * backup.progress, backup.remainingNumberOfPages, backup.totalNumberOfPages);
    } completionHandler:^(NSError *error) {
        isComplete = YES;
        NSLog(@"Completed with error: %@", error);
    }];
    __block BOOL backupIsRunning = YES;
    while (backupIsRunning) {
        dispatch_sync(q, ^{
            NSLog(@"Check");
            if (isComplete) backupIsRunning = NO;
        });
    }
    XCTAssertEquals(1.0f, backup.progress);
}

@end
