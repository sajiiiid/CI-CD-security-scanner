#!/usr/bin/env bats
TEST_DOMAIN="example.com"

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    SCRIPT="${PROJECT_ROOT}/netscan.sh"
}

@test "netscan --help prints usage information" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "netscan --version prints version" {
    run bash "$SCRIPT" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"netscan version"* ]]
}

@test "netscan fails without --target" {
    run bash "$SCRIPT" --scan ssl
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error:"* ]]
}

@test "netscan fails on unknown option" {
    run bash "$SCRIPT" --invalid-flag
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error:"* ]]
}

@test "netscan fails on unknown scan type" {
    run bash "$SCRIPT" --target "$TEST_DOMAIN" --scan bogus
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error:"* ]]
}

@test "netscan --target without value fails" {
    run bash "$SCRIPT" --target
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error:"* ]]
}

@test "netscan --scan without value fails" {
    run bash "$SCRIPT" --scan
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error:"* ]]
}

@test "netscan ssl scan produces certificate output" {
    run bash "$SCRIPT" --target "$TEST_DOMAIN" --scan ssl
    [ "$status" -eq 0 ]
    [[ "$output" == *"SSL/TLS Certificate Check"* ]]
    [[ "$output" == *"Days remaining"* ]]
}
