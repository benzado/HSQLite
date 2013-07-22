//
//  HSQLBackupOperation.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/21/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HSQLite/HSQLDatabase.h>

@class HSQLDatabase;
@class HSQLBackupOperation;

typedef void(^HSQLBackupProgressHandler)(HSQLBackupOperation *op);

@interface HSQLBackupOperation : NSOperation
{
    sqlite3_backup *_backup;
    CFTimeInterval _copyingDuration;
    BOOL _done;
}
@property (nonatomic, readonly) HSQLDatabase *sourceDatabase;
@property (nonatomic, readonly) HSQLDatabase *destinationDatabase;
@property (nonatomic, readonly) int totalNumberOfPages;
@property (nonatomic, readonly) int remainingNumberOfPages;
@property (nonatomic, readonly) float progress;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, copy) void (^progressBlock)(HSQLBackupOperation *);
@end

@interface HSQLDatabase (Backup)
- (HSQLBackupOperation *)backupOperationWithDestinationDatabase:(HSQLDatabase *)destinationDatabase error:(NSError **)error;
@end
