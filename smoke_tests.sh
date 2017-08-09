#!/bin/sh

function test_homepage_return_200 {
    make_request '/'
    parse_status
    if [[ "$status"!="200" ]]
    then
        fail "status code doesn't match"
    fi
}

function test_legacy_url_redirects_to_Blogspot {
    make_request '/2009/07/hello-world.html'
    parse_status
    if [[ "$status" != "301" ]]
    then
        fail "status code doesn't match"
        return
    fi

    expected_location='http://velofastiv.blogspot.com/2009/07/hello-world.html'
    parse_location
    if [[ "$location" != "$expected_location" ]]
    then
        fail "Location header doesn't match"
    fi
}

function make_request {
    url="http://$domain$1"
    echo "Making GET request to '$url'..."
    response=`curl -sIG $url | tr -d '\r' | tee /dev/tty`
}

function parse_status {
    status=`echo "$response" | head -n 1 | awk '{print $2}'`
}

function parse_location {
    location=`echo "$response" | grep 'Location: .*$' | awk '{print $2}'`
}

function fail {
    if [ -n "$1" ]
    then
        echo "<-- Test FAILED because '$1'."
    else
        echo '<-- Test FAILED.'
    fi
    tests_failed=$((tests_failed + 1))
}

function pass {
    echo '<-- Test PASSED.'
    tests_passed=$((tests_passed + 1))
}

function run_all_tests_in_the_current_file {
    functions=`grep -E '^function test_.*$' $0 | awk '{print $2}'`
    for f in $functions
    do
        echo "--> Running '$f'."
        tests_failed_backup=$tests_failed
        $f
        if [[ $tests_failed -eq $tests_failed_backup ]]
        then
            pass
        fi
    done
}

if [ -z $1 ]
then
    echo "ERROR: Domain is not specified."
    echo "Usage:"
    echo "  `basename $0` domain"
    exit -1
fi

domain=$1

tests_passed=0
tests_failed=0

run_all_tests_in_the_current_file

echo Tests passed: $tests_passed
echo Tests failed: $tests_failed

exit $tests_failed
