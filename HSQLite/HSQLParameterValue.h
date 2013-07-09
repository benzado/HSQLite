//
//  HSQLParameterValue.h
//  HSQLite
//
//  Created by Benjamin Ragheb on 6/23/13.
//  Copyright (c) 2013 Heroic Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HSQLValue.h"

@interface HSQLParameterValue : NSObject <HSQLValue>
{
    sqlite3_value *_value;
}
- (instancetype)initWithValue:(sqlite3_value *)value;
@end
