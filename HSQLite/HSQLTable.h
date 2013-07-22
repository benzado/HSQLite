//
//  HSQLTable.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HSQLite/HSQLDatabase.h>

@interface HSQLTable : NSObject
@property (nonatomic, strong, readonly) HSQLDatabase *database;
@property (nonatomic, copy, readonly) NSString *name;
- (BOOL)exists;
- (NSString *)creationQuery;
- (NSUInteger)numberOfRows;
@end

@interface HSQLDatabase (Table)
- (NSArray *)allTables;
- (HSQLTable *)tableNamed:(NSString *)name;
@end
