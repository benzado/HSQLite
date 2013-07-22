//
//  HSQLDatabase.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/21/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HSQLite/HSQLSession.h>

@class HSQLTable;

@interface HSQLDatabase : NSObject
{
    sqlite3 *_handle;
}
@property (nonatomic, strong, readonly) HSQLSession *session;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, readonly) NSString *absolutePath;
@property (nonatomic, readonly, getter = isReadOnly) BOOL readOnly;
// PRAGMA journal_mode
// PRAGMA secure_delete
// PRAGMA mmap_size
// PRAGMA wal_checkpoint
- (void)detachFromSession;
@end

@interface HSQLSession (Database)
@property (nonatomic, readonly) HSQLDatabase *mainDatabase;
@property (nonatomic, readonly) HSQLDatabase *tempDatabase;
- (HSQLDatabase *)databaseNamed:(NSString *)name;
- (NSArray *)allDatabases;
- (void)attachDatabaseFileAtPath:(NSString *)path forName:(NSString *)name error:(NSError **)error;
@end

