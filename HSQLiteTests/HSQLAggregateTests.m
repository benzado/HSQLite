//
//  HSQLAggregateTests.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 8/29/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <HSQLite/HSQLite.h>

@interface MedianAggregateFunction : NSObject <HSQLAggregateFunction>
{
    NSMutableArray *_values;
}
@end

@implementation MedianAggregateFunction

+ (NSString *)name
{
    return @"MEDIAN";
}

+ (int)numberOfArguments
{
    return 1;
}

- (id)init
{
    if ((self = [super init])) {
        _values = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)performStepWithContext:(HSQLFunctionContext *)context
{
    id <HSQLValue> value = context[0];
    if ( ! [value isNull]) {
        [_values addObject:@([value doubleValue])];
    }
}

- (void)computeResultWithContext:(HSQLFunctionContext *)context
{
    if ([_values count] == 0) {
        [context returnNull]; return;
    }
    if ([_values count] == 1) {
        [context returnDouble:[_values[0] doubleValue]]; return;
    }
    [_values sortUsingSelector:@selector(compare:)];
    NSInteger mid = [_values count] / 2;
    double median;
    if ([_values count] % 2) {
        median = [_values[mid] doubleValue];
    } else {
        double a = [_values[mid - 1] doubleValue];
        double b = [_values[mid] doubleValue];
        median = (a + b) / 2.0;
    }
    [context returnDouble:median];
}

@end

@interface HSQLAggregateTests : XCTestCase

@end

@implementation HSQLAggregateTests

- (void)testBadRegistration
{
    HSQLSession *db = [HSQLSession sessionWithMemoryDatabase];
    XCTAssertThrows([db defineAggregateFunction:[NSObject class]]);
}

- (void)testAggregateFunction
{
    HSQLSession *db = [HSQLSession sessionWithMemoryDatabase];
    [db defineAggregateFunction:[MedianAggregateFunction class]];
    
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
