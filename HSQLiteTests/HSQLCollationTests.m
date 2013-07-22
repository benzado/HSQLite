//
//  HSQLCollationTests.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <HSQLite/HSQLite.h>

@interface HSQLCollationTests : XCTestCase
{
    HSQLSession *db;
}
@end

@implementation HSQLCollationTests

- (void)setUp
{
    [super setUp];
    NSError *error = nil;
    NSURL *sqlURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"letters" withExtension:@"sql"];
    NSString *sql = [NSString stringWithContentsOfURL:sqlURL encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNotNil(sql);
    XCTAssertNil(error);
    db = [HSQLSession sessionWithMemoryDatabase];
    [db executeQuery:sql error:&error];
    XCTAssertNil(error);
}

- (void)tearDown
{
    [db close];
    db = nil;
    [super tearDown];
}

- (void)testLettersData
{
    __block int count = -1;
    HSQLStatement *st = [db statementWithQuery:@"SELECT COUNT(*) FROM `letters`" error:NULL];
    [st executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        count = [row[0] intValue];
    }];
    XCTAssertEquals(17, count);
}

- (NSString *)sequenceFromQuery:(NSString *)query
{
    HSQLStatement *st = [db statementWithQuery:query error:NULL];
    NSArray *letters = [st arrayByExecutingWithBlock:^id(HSQLRow *row, BOOL *stop) {
        return [row[@"letter"] stringValue];
    }];
    return [letters componentsJoinedByString:@" "];
}

- (void)testDefaultCollation
{
    NSString *cat = [self sequenceFromQuery:@"SELECT * FROM `letters` ORDER BY `letter`"];
    XCTAssertEqualObjects(cat, @"A E Z a e Á Â Ã Å É Ê á â ã å é ê");
}

- (void)testCaseInsensitiveCollation
{
    [db defineCollationNamed:@"case_insensitive" comparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 caseInsensitiveCompare:obj2];
    }];
    NSArray *names = [db allCollationNames];
    XCTAssertTrue([names containsObject:@"case_insensitive"]);
    NSString *cat = [self sequenceFromQuery:@"SELECT * FROM `letters` ORDER BY `letter` COLLATE case_insensitive"];
    XCTAssertEqualObjects(cat, @"A a Á á Â â Ã ã Å å E e É é Ê ê Z");
}

- (void)testLocalizedCollation
{
    [db setUndefinedCollationHandler:^(HSQLSession *session, NSString *neededCollationName) {
        if ([neededCollationName isEqualToString:@"localized"]) {
            [session defineCollationNamed:@"localized" comparator:^NSComparisonResult(id obj1, id obj2) {
                return [obj1 localizedCompare:obj2];
            }];
        }
    }];
    NSArray *names = [db allCollationNames];
    XCTAssertFalse([names containsObject:@"localized"]);
    NSString *cat = [self sequenceFromQuery:@"SELECT * FROM `letters` ORDER BY `letter` COLLATE localized"];
    XCTAssertEqualObjects(cat, @"a A á Á â Â å Å ã Ã e E é É ê Ê Z");
    names = [db allCollationNames];
    XCTAssertTrue([names containsObject:@"localized"]);
}

- testUnknownCollation
{
    __block NSString *name = nil;
    [db setUndefinedCollationHandler:^(HSQLSession *db, NSString *neededCollationName) {
        name = neededCollationName;
    }];
    NSError *error = nil;
    [db executeQuery:@"SELECT * FROM `letters` ORDER BY `letter` COLLATE etalloc" error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(name, @"etalloc");
}

@end
