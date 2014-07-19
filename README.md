predis
------

A Redis server implemented in 100% pure Perl which proxies commands to local storage.

This server will listen upon a network, and accept/process Redis commands.  As such it can be useful for hacking around interesting problems.

Because the storage is persistent database-values can be stored between different invocations.

Currently we have two back-ends implemented:

* An SQLite database-based back-end.
* A Berkeley database back-end.
* An LMDB database back-end.


Limitations
------------

The implementation includes the string-primitives for all back-ends, other
structures are ignored in the name of simplicity.

For each of the backends the following primitives are implemented:

* `get( key )`
* `strlen( key )`
* `set( key, value )`
* `incr( key )`
* `incrby( key, amount )`
* `decr( key )`
* `decrby( key, amount )`
* `del( key )`

Some of the set-primitives are supported **ONLY** with the SQLite backend:

* `sadd(key,val)`
* `smembers(key)`
* `sdel(key,val)`


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

There are some simple tests included beneath `t/` which can be executed as expected:

    $ prove --shuffle t/


Benchmarks
----------

There is a trivial [benchmark script](benchmark) included, which will run a number
of operations for 5 seconds at a time, and count the number that completed.

This is not intended to be an exhaustive benchmark, merely something to give an
order of magnitude comparison between native redis and predis.

Upon my test system the following results were achieved:

Redis:

    incr_decr  30895 requests in 5 seconds
    get_set  33267 requests in 5 seconds
    set_del  38706 requests in 5 seconds

Predis using SQLite:

    incr_decr 11064 requests in 5 seconds
    get_set   13100 requests in 5 seconds
    set_del   11769 requests in 5 seconds

Predis using BDB (launched via `./predis  --backend=BDB`)

    incr_decr 14926 requests in 5 seconds
    get_set   15896 requests in 5 seconds
    set_del   16282 requests in 5 seconds

Predis using LMDB (launched via `./predis  --backend=LMDB`)

    incr_decr 14425 requests in 5 seconds
    get_set   14827 requests in 5 seconds
    set_del   14841 requests in 5 seconds


This suggests that predis is 3-4 times slower than Redis using SQlite, and half as fast using the Berkeley database back-end, but obviously benchmarks are unrealistic and will vary depending on your system and use-case.


Extending
---------

Obviously I've only covered the simple case(s) so far.

To make this more Redis-like we'd need to add the set/hash functions.

The sets should be simple to add at least, and there are two choices:

* Either allow multiple values for each key.
* Or store JSON-encoded Arrays as key-members.

We'd probably need to rework things to store hashes, although again we
could use JSON-encoded Perl Hashes for the storage.

(I suspect we'd want to update the storage-table to have three fields in this case: `key`, `val` and `type`.  Where `type` would be an ENUM between `str`, `array`, or `hash`.)

The coding isn't hard, I just don't need it yet - so pull requests welcome.

(This might be more complex now we also support the Berkeley back-end.)

Steve
--
