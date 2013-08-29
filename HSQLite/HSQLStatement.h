//
//  HSQLStatement.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HSQLSession;
@class HSQLRow;

@interface HSQLStatement : NSObject
{
    sqlite3_stmt *_stmt;
    NSDictionary *_columnIndexesByName;
    NSMutableDictionary *_boundObjects;
}
@property (nonatomic, readonly, strong) HSQLSession *session;
- (void)close;
- (NSString *)query;
- (BOOL)isReadOnly;
- (BOOL)isBusy;
- (int)numberOfParameters;
- (int)numberOfColumns;
- (int)indexForColumnName:(NSString *)name;
// Binding Parameters
- (void)setObject:(id)anObject atIndexedSubscript:(NSUInteger)index;
- (id)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)key;
- (id)objectforKeyedSubscript:(id<NSCopying>)key;
- (void)executeWithBlock:(void(^)(HSQLRow *row, BOOL *stop))block;
- (void)execute;
- (NSArray *)arrayByExecutingWithBlock:(id(^)(HSQLRow *row, BOOL *stop))block;
- (void)clearBindings;
@end
