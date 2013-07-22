//
//  HSQLBlob.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HSQLite/HSQLTable.h>

@interface HSQLBlob : NSObject
@property (nonatomic, readonly) NSUInteger length;
@property (nonatomic, readonly) NSUInteger cursor;
- (NSData *)dataWithRange:(NSRange)range;
- (void)getBytes:(void *)bytes length:(NSUInteger)length;
- (void)getBytes:(void *)bytes range:(NSRange)range;
- (NSData *)readDataOfLength:(NSUInteger)length;
- (NSData *)readDataToEndOfBlob;
- (void)rewind;
- (void)seekToOffset:(NSUInteger)offset;
- (BOOL)isAtEnd;
- (void)reopenWithRow:(sqlite3_int64)row;
- (void)close;
@end

@interface HSQLMutableBlob : HSQLBlob
- (void)replaceBytesAtOffset:(NSUInteger)offset withData:(NSData *)data;
- (void)replaceBytesInRange:(NSRange)range withBytes:(const void *)bytes;
- (void)setData:(NSData *)data;
- (void)writeData:(NSData *)data;
- (void)writeBytes:(const void *)bytes length:(NSUInteger)length;
@end

@interface HSQLTable (Blob)
- (HSQLBlob *)blobForRow:(sqlite3_int64)row inColumnNamed:(NSString *)name;
- (HSQLMutableBlob *)mutableBlobForRow:(sqlite3_int64)row inColumnNamed:(NSString *)name;
@end
