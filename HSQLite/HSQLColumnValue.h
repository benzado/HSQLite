//
//  HSQLColumnValue.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/22/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HSQLValue.h"

@interface HSQLColumnValue : NSObject <HSQLValue>
{
    sqlite3_stmt *_stmt;
    int _idx;
}
- (instancetype)initWithColumnIndex:(int)idx stmt:(sqlite3_stmt *)stmt;
@end

@interface HSQLInvalidColumnValue : HSQLColumnValue
@end
