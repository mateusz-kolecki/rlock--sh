# Work in progress.

## rlock-sh

Utility similar to `flock` but works with Redis as backend and it is implemented in bash.

Example usage. Run this in two terminals in same time:

```bash
rlock-sh -v -H 127.0.0.1 -p 6379 -l my-lock-key-name bash <<EOF
    echo Those lines are synchronized
    sleep 10
EOF
```

Terminal 1 output:

```
rlock-sh: acquiring lock (my-lock-key-name=Sm7xRnEpJQI5dAkltTCMDeOUFBMFhfQI)
rlock-sh: lock acquired after 0 seconds
Those lines are synchronized
rlock-sh: releasing lock
```

Terminal 2 output:

```
rlock-sh: acquiring lock (my-lock-key-name=B0oc2HvLEZs485fqRO9wzz26xc6zHVcd)
rlock-sh: lock acquired after 10 seconds
Those lines are synchronized
rlock-sh: releasing lock
```

## Help:

```
Usage:

  rlock-sh [OPTIONS...] [CMD] [CMD OPTIONS...]
  rlock-sh [OPTIONS...] -- [CMD] [CMD OPTIONS...]

  Acquire lock by creating key in Redis using NX flag. After acquiring lock execure CMD.
  When CMD finishes then lock is released by removing key.

Options:

  -h|--help                 Show this usage help
  -v|--verbose              Print debug information on stderr

  -l|--lock-name=LOCK_KEY   (string) Name of the key that will be created (default: rlock-sh)
  -t|--lock-ttl=LOCK_TTL    (int) Number of seconds for lock TTL (default: 300)

  -H|--host=REDIS_HOST      (string) Redis host name or ip (default: 127.0.0.1)
  -p|--port=REDIS_PORT      (int) Redis TCP port (default: 6379)
  -d|--database=REDIS_DB    (int) Redis database to select (default: none)
  -a|--auth=REDIS_AUTH      (string) Redis authentication (default: none)

  -r|--connect-max-retry=REDIS_CON_MAX_RETRY
                            (int) Maximum number of connection attempts (default: 60)

  -T|--acquire-timeout=LOCK_ACQUIRE_TIMEOUT
                            (int) Temeout for acquiring lock in seconds (default: 150)

  -S|--acquire-sleep=LOCK_ACQUIRE_SLEEP
                            (int|float) Time in second to sleep betwean lock acquire retries
                            (default: 1)
                            Not on every system `sleep` command can receive fraction.
                            See man pages for sleep on your system.
```

