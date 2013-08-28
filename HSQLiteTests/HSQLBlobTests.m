//
//  HSQLBlobTests.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <HSQLite/HSQLite.h>

@interface HSQLBlobTests : XCTestCase
{
    HSQLTable *table;
    NSData *origData;
    NSData *moreData;
}
@end

@implementation HSQLBlobTests

- (void)setUp
{
    [super setUp];

    NSFileHandle *random = [NSFileHandle fileHandleForReadingAtPath:@"/dev/random"];
    origData = [random readDataOfLength:128];
    moreData = [random readDataOfLength:128];
    [random closeFile];
    
    HSQLSession *session = [HSQLSession sessionWithMemoryDatabase];
    [session executeQuery:@"CREATE TABLE test (blob)" error:nil];

    HSQLStatement *st = [session statementWithQuery:@"INSERT INTO test VALUES (?)" error:nil];
    st[1] = origData;
    [st executeWithBlock:NULL];
    
    table = [[session mainDatabase] tableNamed:@"test"];
}

- (void)tearDown
{
    table = nil;
    [super tearDown];
}

- (void)testNoSuchBlob
{
    XCTAssertThrows([table blobForRow:1 inColumnNamed:@"bleb"]);
    XCTAssertThrows([table blobForRow:2 inColumnNamed:@"blob"]);
}

- (void)testBlobDataWithRange
{
    HSQLBlob *blob = [table blobForRow:1 inColumnNamed:@"blob"];
    XCTAssertNotNil(blob);
    XCTAssertEqual(origData.length, blob.length);
    NSData *blobData = [blob dataWithRange:NSMakeRange(0, blob.length)];
    XCTAssertEqualObjects(blobData, origData);
}

- (void)testBlobReadData
{
    HSQLBlob *blob = [table blobForRow:1 inColumnNamed:@"blob"];
    XCTAssertNotNil(blob);
    XCTAssertEqual(origData.length, blob.length);
    NSMutableData *buffer = [NSMutableData dataWithCapacity:origData.length];
    while (![blob isAtEnd]) {
        NSData *chunk = [blob readDataOfLength:20];
        [buffer appendData:chunk];
    }
    XCTAssertEqualObjects(buffer, origData);
}

- (void)testBlobReplaceData
{
    HSQLMutableBlob *blob = [table mutableBlobForRow:1 inColumnNamed:@"blob"];
    XCTAssertNotNil(blob);
    XCTAssertEqual(origData.length, blob.length);
    [blob replaceBytesAtOffset:0 withData:moreData];
    [blob close];
    HSQLStatement *st = [table.database.session statementWithQuery:@"SELECT blob FROM test WHERE rowid = 1" error:nil];
    NSArray *array = [st arrayByExecutingWithBlock:^id(HSQLRow *row, BOOL *stop) {
        return [row[0] dataValue];
    }];
    XCTAssertEqual(1u, [array count]);
    XCTAssertEqualObjects(array[0], moreData);
}

- (void)testBlobWriteData
{
    HSQLMutableBlob *blob = [table mutableBlobForRow:1 inColumnNamed:@"blob"];
    XCTAssertNotNil(blob);
    XCTAssertEqual(origData.length, blob.length);
    NSRange r = NSMakeRange(0, 16);
    for (r.location = 0; r.location < moreData.length; r.location += 16) {
        NSData *chunk = [moreData subdataWithRange:r];
        [blob writeData:chunk];
    }
    XCTAssertTrue([blob isAtEnd]);
    [blob close];
    HSQLStatement *st = [table.database.session statementWithQuery:@"SELECT blob FROM test WHERE rowid = 1" error:nil];
    NSArray *array = [st arrayByExecutingWithBlock:^id(HSQLRow *row, BOOL *stop) {
        return [row[0] dataValue];
    }];
    XCTAssertEqual(1u, [array count]);
    XCTAssertEqualObjects(array[0], moreData);
}

/*
- (void)testDeferredBlob
{
    HSQLStatement *st = [table.database.session statementWithQuery:@"INSERT INTO test VALUES (?)" error:nil];
    st[1] = [HSQLDeferredBlob deferredBlobOfLength:[moreData length] withBlock:^(HSQLMutableBlob *blob) {
        [blob setData:moreData];
    }];
    [st executeWithBlock:NULL];

    HSQLBlob *blob = [table blobForRow:[table.database.session lastInsertRowID] inColumnNamed:@"blob"];
    NSData *data = [blob dataWithRange:NSMakeRange(0, blob.length)];
    XCTAssertEqualObjects(data, moreData);
}
*/
/*
 It would be nice to provide this functionality, but unfortunately it is not a
 simple matter to introspect the information required to open the Blob after the
 statement has executed. For example, we can't be certain of whether the
 statement is an INSERT or UPDATE, or what table it is writing to.
 
 Maybe syntax like [table insertStatementWithColumns:(NSString *)name, ...]
 which creates a subclass, HSQLInsertStatement. Then it would have access to
 all the information it needed.
 */

@end
