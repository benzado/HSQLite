//
//  HSQLBackupOperation.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/21/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLBackupOperation.h"
#import "HSQLSession.h"
#import "HSQLSession+Private.h"

static const NSTimeInterval kHSQLProgressNotificationInterval = 0.1;
static const int kHSQLInitialBatchSize = 1024;
static const int kHSQLMinimumBatchSize = 16;

@implementation HSQLBackupOperation

- (id)initWithBackup:(sqlite3_backup *)backup SourceDatabase:(HSQLDatabase *)srcDb destinationDatabase:(HSQLDatabase *)dstDb
{
    if ((self = [super init])) {
        _backup = backup;
        _sourceDatabase = srcDb;
        _destinationDatabase = dstDb;
    }
    return self;
}

@dynamic totalNumberOfPages;

- (int)totalNumberOfPages
{
    if (_backup == NULL) return 0;
    return sqlite3_backup_pagecount(_backup);
}

@dynamic remainingNumberOfPages;

- (int)remainingNumberOfPages
{
    if (_backup == NULL) return 0;
    return sqlite3_backup_remaining(_backup);
}

@dynamic progress;

- (float)progress
{
    if (_backup == NULL) return _error ? 0.0 : 1.0;
    const float n = sqlite3_backup_remaining(_backup);
    const float d = sqlite3_backup_pagecount(_backup);
    if (d > 0) {
        return ((d - n) / d);
    } else {
        return 0;
    }
}

- (void)copyPagesBatchOfSize:(int)batchSize
{
    if (_backup == NULL) return;
    int r = sqlite3_backup_step(_backup, batchSize);
    switch (r) {
        case SQLITE_OK:
            return;
        case SQLITE_LOCKED:
        case SQLITE_BUSY:
            // non-fatal errors, try again later
            NSLog(@"warning: sqlite_backup_step result %02x", r);
            return;
        case SQLITE_DONE:
            _done = YES;
            return;
        default: {
            NSError *error = nil;
            [HSQLSession raiseExceptionOrGetError:&error forResultCode:r];
            _error = error;
        }
    }
}

- (void)copyPagesForDuration:(NSTimeInterval)duration
{
    int batchSize;
    if (_copyingDuration == 0) {
        batchSize = kHSQLInitialBatchSize;
    } else {
        double pagesCopied = self.totalNumberOfPages - self.remainingNumberOfPages;
        double pagesPerSecond = pagesCopied / _copyingDuration;
        batchSize = MAX(kHSQLMinimumBatchSize, ceil(pagesPerSecond * duration));
    }
    CFAbsoluteTime beginTime = CFAbsoluteTimeGetCurrent();
    [self copyPagesBatchOfSize:batchSize];
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    _copyingDuration += (endTime - beginTime);
}

- (void)main
{
    if (self.progressBlock) {
        self.progressBlock(self);
    }
    while ( ! (_done || [self isCancelled] || (_error != nil))) {
        [self copyPagesForDuration:kHSQLProgressNotificationInterval];
        if (self.progressBlock) {
            self.progressBlock(self);
        }
    }
    sqlite3_backup_finish(_backup);
    _backup = NULL;
    self.progressBlock = nil; // break possible circular reference
}

@end

@implementation HSQLDatabase (Backup)

- (HSQLBackupOperation *)backupOperationWithDestinationDatabase:(HSQLDatabase *)destinationDatabase error:(NSError *__autoreleasing *)error
{
    sqlite3_backup *backup;
    
    backup = sqlite3_backup_init(destinationDatabase->_handle,
                                 [destinationDatabase.name UTF8String],
                                 self->_handle,
                                 [self.name UTF8String]);
    if (backup) {
        return [[HSQLBackupOperation alloc] initWithBackup:backup
                                            SourceDatabase:self
                                       destinationDatabase:destinationDatabase];
    } else {
        [destinationDatabase.session raiseExceptionOrGetError:error];
        return nil;
    }
}

@end
