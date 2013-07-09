//
//  HSQLStatement.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HSQLDatabase;
@class HSQLRow;

@interface HSQLStatement : NSObject
{
    HSQLDatabase *_database;
    sqlite3_stmt *_stmt;
    NSDictionary *_columnIndexesByName;
}
- (void)close;
- (NSString *)query;
- (BOOL)isReadOnly;
- (BOOL)isBusy;
- (int)numberOfParameters;
- (int)numberOfColumns;
- (int)indexForColumnName:(NSString *)name;
// Binding Parameters
- (void)setObject:(id)anObject atIndexedSubscript:(NSUInteger)index;
- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)key;
- (void)executeWithBlock:(void(^)(HSQLRow *row, BOOL *stop))block;
- (void)clearBindings;
@end
