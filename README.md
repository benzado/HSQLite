HSQLite, an Objective-C library for working with SQLite databases
=================================================================

[SQLite][] is an embedded database library. If you're not familiar with it, you
should [read about it][About SQLite].

HSQLite is an Objective-C "wrapper" around SQLite, similar to
[Gus Mueller's FMDB][FMDB]. It benefits from being a newer codebase, and is
built around support for ARC, blocks, and subscripts. On the other hand, it
isn't nearly as widely used and tested as FMDB. On the third hand, it has a
pretty extensive set of unit tests.

While comprehensive, this code should be considered alpha-quality: I'm still
capriciously changing class and method names, and the library's approach to
exception and error handling probably needs revisiting.

Quick synopsis:

    #import <HSQLite/HSQLite.h>
    
    // Quickly create a database in memory; on-disk databases are supported, too :-)
    HSQLSession *db = [HSQLSession sessionWithMemoryDatabase];

    // Define a custom function using a block!
    [db defineScalarFunctionWithName:@"SIN" numberOfArguments:1 block:^(HSQLFunctionContext *context) {
        double angle = [[context argumentValueAtIndex:0] doubleValue];
        double sine = sin(angle);
        [context returnDouble:sine];
    }];

    HSQLStatement *stmt = [db statementWithQuery:@"SELECT `n`, SIN(`n`) FROM `number_table` WHERE `n` < ?"];

    // This is one way to set a parameter's value.
    stmt[1] = @(2 * 3.14159);

    // Provide a block that is called with every result row.
    [stmt executeWithBlock:^(HSQLRow *row, BOOL *stop) {
        NSLog(@"sin(%f) = %f", [row[@"n"] doubleValue], [row[1] doubleValue]);
    }];

    [db close];

Browse the test code for more usage examples.

_Documentation forthcoming._

You can also email your questions to <ben@benzado.com>.

[FMDB]: https://github.com/ccgus/fmdb
[SQLite]: http://www.sqlite.org
[About SQLite]: http://www.sqlite.org/about.html
