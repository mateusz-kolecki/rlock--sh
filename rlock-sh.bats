#!/usr/bin/env bats

load './node_modules/bats-support/load.bash'
load './node_modules/bats-assert/load.bash'

function main {
    bash ${BATS_TEST_DIRNAME}/rlock-sh "$@"
}

function fake_redis_success_flow {
    local redis_responses=(+OK :1 +OK)

    printf '%s\r\n' "${redis_responses[@]}" | nc -l 1234 > ${BATS_TMPDIR}/input.log
}

function fake_redis_lock_exists_responses {
    mkfifo ${BATS_TMPDIR}/fifo

    nc -l 1234 < ${BATS_TMPDIR}/fifo | (while read line; do
        if [[ "$line" =~ "101010" ]]; then
            printf '$-1\r\n'
        fi
    done >> ${BATS_TMPDIR}/fifo )

    rm -f ${BATS_TMPDIR}/fifo
}


@test "invoking with --help should display uage" {
    run main --help

    assert_success
    assert_line --index 0 "Usage:"
}

@test "invoking with -h should display uage" {
    run main -h

    assert_success
    assert_line --index 0 "Usage:"
}

@test "with no CMD lock is created and released (short options)" {
    fake_redis_success_flow &

    run main -v -p 1234

    assert_success

    assert_line --index 0 --regexp '^rlock-sh: acquiring lock \(rlock-sh=[a-zA-Z0-9]+\)$'
    assert_line --index 1 --regexp '^rlock-sh: lock acquired after [0-9]+ seconds$'
    assert_line --index 2 --regexp '^rlock-sh: releasing lock$'
}

@test "with no CMD lock is created and released (long options)" {
    fake_redis_success_flow &

    run main --verbose --port 1234

    assert_success

    assert_line --index 0 --regexp '^rlock-sh: acquiring lock \(rlock-sh=[a-zA-Z0-9]+\)$'
    assert_line --index 1 --regexp '^rlock-sh: lock acquired after [0-9]+ seconds$'
    assert_line --index 2 --regexp '^rlock-sh: releasing lock$'
}

@test "with provided CMD lock is created and released after command execution (long options)" {
    fake_redis_success_flow &

    run main --verbose --port 1234 -- bash -c 'echo "command output"'

    assert_success

    assert_line --index 0 --regexp '^rlock-sh: acquiring lock \(rlock-sh=[a-zA-Z0-9]+\)$'
    assert_line --index 1 --regexp '^rlock-sh: lock acquired after [0-9]+ seconds$'
    assert_line --index 2 --regexp '^command output$'
    assert_line --index 3 --regexp '^rlock-sh: releasing lock$'
}


@test "creates key given by option --lock-name" {
    fake_redis_success_flow &

    main --verbose --port 1234 --lock-name foo-bar

    run cat ${BATS_TMPDIR}/input.log

    expected_lines=(
        '\*6' '\$3' 'SET' '\$7' 'foo-bar'
        '\$32' '[a-zA-Z0-9]{32}'
    )

    assert_output --regexp ^$(printf '%s\r\n' ${expected_lines[@]})
}

@test "when acquire timeout then do not run CMD" {
    fake_redis_lock_exists_responses &

    run main -v -p 1234 -t 101010 -T 2 -- -- echo 'should not be there'

    assert_failure

    refute_output --partial 'should not be there'
    assert_output --partial 'rlock-sh: ERROR acquire lock timeout'
}