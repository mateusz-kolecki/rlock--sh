#!/usr/bin/env bats

function main {
    bash ${BATS_TEST_DIRNAME}/rlock-sh "$@"
}

@test "invoking with --help should display uage" {
    run main --help

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "invoking with -h should display uage" {
    run main -h

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "with no CMD lock is created and released" {
    redis_responses=(
        +OK
        :1
        +OK
    )

    printf '%s\r\n' "${redis_responses[@]}" | nc -l 1234 > ${BATS_TMPDIR}/input.log &

    run main --port 1234

    [ "$status" -eq 0 ]
}
