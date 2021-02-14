# Work in progress.

## rlock-sh

Utility similar to `flock` but works with Redis as backend and it is implemented in bash.

Example usage. Run this in two terminals in same time:

```
rlock-sh -v -h 127.0.0.1 -p 6379 -l my-lock-key-name bash <<EOF
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

