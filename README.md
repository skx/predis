predis
------

A Redis server implemented in 100% pure Perl which proxies commands to a local
SQLite instance.

This server will listen upon a network, and accept/process Redis commands.  As such it
can be useful for hacking around interesting problems.

Because the storage is an SQLite database values will persist between invocations, just
like the real thing.


Limitations
------------

Currently the implementation is incomplete, which means that most of the Redis
data-structures are not implemented.

Currently the following primitives are implemented, all those ones that I need:

* `get( key )`
* `set( key, value )`
* `incr( key )`
* `decr( key )`
* `del( key )`


Testing
-------

The code can be tested, as expected, with the `redis-cli` script.

First start the server:

    $ perl predis


Then experiment

    $ redis-cli set foo "$(cat /etc/passwd )"
    OK
    $ redis-cli get foo | head -n 5
    root:x:0:0:root:/root:/bin/bash
    daemon:x:1:1:daemon:/usr/sbin:/bin/sh
    ..
    ..
    ..


Steve
-- 
