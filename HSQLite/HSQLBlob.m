//
//  HSQLBlob.m
//  HSQLite
//
//  Created by Benjamin Ragheb on 7/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import "HSQLBlob.h"
#import "HSQLTable.h"
#import "HSQLDatabase.h"
#import "HSQLSession.h"
#import "HSQLSession+Private.h"

static const int HSQLBlobFlagsReadOnly = 0;
static const int HSQLBlobFlagsReadWrite = 1;

@implementation HSQLBlob
{
    @protected
    sqlite3_blob *_blob;
    NSUInteger _cursor;
}

@dynamic length;
@synthesize cursor = _cursor;

- (instancetype)initWithBlob:(sqlite3_blob *)blob
{
    if ((self = [super init])) {
        _blob = blob;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

- (void)close
{
    sqlite3_blob_close(_blob); _blob = NULL;
}

- (void)reopenWithRow:(sqlite3_int64)row
{
    int r = sqlite3_blob_reopen(_blob, row);
    [HSQLSession raiseExceptionOrGetError:nil forResultCode:r];
    _cursor = 0;
}

- (NSUInteger)length
{
    return sqlite3_blob_bytes(_blob);
}

- (void)checkRange:(NSRange)range
{
    if ((range.location + range.length) > self.length) {
        [NSException
         raise:NSRangeException
         format:@"Range %@ falls outside Blob of length %d", NSStringFromRange(range), self.length];
    }
}

- (NSData *)dataWithRange:(NSRange)range
{
    [self checkRange:range];
    void *buffer = malloc(range.length);
    sqlite3_blob_read(_blob, buffer, range.length, range.location);
    return [NSData dataWithBytesNoCopy:buffer length:range.length freeWhenDone:YES];
}

- (void)getBytes:(void *)bytes length:(NSUInteger)length
{
    [self checkRange:NSMakeRange(0, length)];
    sqlite3_blob_read(_blob, bytes, length, 0);
}

- (void)getBytes:(void *)bytes range:(NSRange)range
{
    [self checkRange:range];
    sqlite3_blob_read(_blob, bytes, range.length, range.location);
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    if (_cursor >= self.length) return nil;
    NSRange range = NSMakeRange(_cursor, length);
    if (range.location + range.length > self.length) {
        range.length = self.length - range.location;
    }
    _cursor += range.length;
    return [self dataWithRange:range];
}

- (NSData *)readDataToEndOfBlob
{
    return [self readDataOfLength:(self.length - _cursor)];
}

- (void)rewind
{
    _cursor = 0;
}

- (void)seekToOffset:(NSUInteger)offset
{
    [self checkRange:NSMakeRange(offset, 0)];
    _cursor = offset;
}

- (BOOL)isAtEnd
{
    return _cursor >= self.length;
}

@end

@implementation HSQLMutableBlob

- (void)replaceBytesAtOffset:(NSUInteger)offset withData:(NSData *)data
{
    [self checkRange:NSMakeRange(offset, [data length])];
    sqlite3_blob_write(_blob, [data bytes], [data length], offset);
}

- (void)replaceBytesInRange:(NSRange)range withBytes:(const void *)bytes
{
    [self checkRange:range];
    sqlite3_blob_write(_blob, bytes, range.length, range.location);
}

- (void)setData:(NSData *)data
{
    if ([data length] != self.length) {
        [NSException
         raise:NSRangeException
         format:@"Blob and data are not the same length (%d, %d)", self.length, [data length]];
    }
    [self replaceBytesAtOffset:0 withData:data];
}

- (void)writeBytes:(const void *)bytes length:(NSUInteger)length
{
    NSRange range = NSMakeRange(self->_cursor, length);
    [self replaceBytesInRange:range withBytes:bytes];
    _cursor += range.length;
}

- (void)writeData:(NSData *)data
{
    [self writeBytes:[data bytes] length:[data length]];
}

@end

@implementation HSQLTable (Blob)

- (HSQLBlob *)blobForRow:(sqlite3_int64)row inColumnNamed:(NSString *)name
{
    sqlite3_blob *blob = NULL;
    sqlite3_blob_open([self.database.session handle],
                      [self.database.name UTF8String],
                      [self.name UTF8String],
                      [name UTF8String],
                      row,
                      HSQLBlobFlagsReadOnly,
                      &blob);
    if (blob) {
        return [[HSQLBlob alloc] initWithBlob:blob];
    } else {
        [self.database.session raiseExceptionOrGetError:nil];
        return nil;
    }
}

- (HSQLMutableBlob *)mutableBlobForRow:(sqlite3_int64)row inColumnNamed:(NSString *)name
{
    sqlite3_blob *blob = NULL;
    sqlite3_blob_open([self.database.session handle],
                      [self.database.name UTF8String],
                      [self.name UTF8String],
                      [name UTF8String],
                      row,
                      HSQLBlobFlagsReadWrite,
                      &blob);
    if (blob) {
        return [[HSQLMutableBlob alloc] initWithBlob:blob];
    } else {
        [self.database.session raiseExceptionOrGetError:nil];
        return nil;
    }
}

@end