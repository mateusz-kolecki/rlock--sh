# rlock-sh

![master build status](https://github.com/mateusz-kolecki/rlock-sh/workflows/CI/badge.svg?branch=master)

---

Execute bash commands only when lock is acquired in Redis.

Utility similar to `flock` but works with Redis as backend, and it is implemented purely in `bash`.

Example usage. Run this in two terminals in the same time:

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

## Install

`rlock-sh` is self-contained bash script with no runtime dependency other than Redis.
Copy that file to location in your `$PATH` and enable the executable flag.

```
curl https://raw.githubusercontent.com/mateusz-kolecki/rlock-sh/master/rlock-sh | sudo tee /usr/bin/rlock-sh
sudo chmod +x /usr/bin/rlock-sh
```

## How it works?

Script follows "*Correct implementation with a single instance*" form this https://redis.io/topics/distlock
Redis documentation.

Long story short, script execute those steps in green path:

  * Connect to Redis with `bash` build-in tcp capabilities (no `nc` required)
  * Send `SET key-name random-value NX PX 30000` command
    * `NX` option make this command to fail when key already exists (other process already acquired lock)
    * repeat that in a loop (until a timeout)
  * When key is created (lock acquired) then given command is executed
  * After command finishes `key-name` key is deleted (some special care is done, read link above). 

## Where it can be useful?

I'm using this in my `k8s` production environment to synchronize multiple replicas of my pod in
initialization stage - only one container at once can execute DB migrations. 

## Help:

```
Usage:

  rlock-sh [OPTIONS...] [CMD] [CMD OPTIONS...]
  rlock-sh [OPTIONS...] -- [CMD] [CMD OPTIONS...]

  Acquire lock by creating key in Redis using NX flag. After acquiring lock execure CMD.
  When CMD finishes then lock is released by removing key.

Options:

  -h, --help                 Show this usage help
  -v, --verbose              Print debug information on stderr

  -l, --lock-name=LOCK_KEY   (string) Name of the key that will be created (default: rlock-sh)
  -t, --lock-ttl=LOCK_TTL    (int) Number of seconds for lock TTL (default: 300)

  -H, --host=REDIS_HOST      (string) Redis host name or ip (default: 127.0.0.1)
  -p, --port=REDIS_PORT      (int) Redis TCP port (default: 6379)
  -d, --database=REDIS_DB    (int) Redis database to select (default: none)
  -a, --auth=REDIS_AUTH      (string) Redis authentication (default: none)

  -r, --connect-max-retry=REDIS_CON_MAX_RETRY
                            (int) Maximum number of connection attempts (default: 60)

  -T, --acquire-timeout=LOCK_ACQUIRE_TIMEOUT
                            (int) Temeout for acquiring lock in seconds (default: 150)

  -S, --acquire-sleep=LOCK_ACQUIRE_SLEEP
                            (int|float) Time in second to sleep betwean lock acquire retries
                            (default: 1)
                            Not on every system `sleep` command can receive fraction.
                            See man pages for sleep on your system.

Majority of options can be set by environment variables.
Here is the list (compare that with options above):

  - REDIS_HOST
  - REDIS_PORT
  - REDIS_DB
  - REDIS_AUTH
  - REDIS_CON_MAX_RETRY
  - LOCK_KEY
  - LOCK_TTL
  - LOCK_ACQUIRE_TIMEOUT
  - LOCK_ACQUIRE_SLEEP
```

