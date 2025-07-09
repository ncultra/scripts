#!/usr/bin/env bash

ONCE=0
MIGRATE_ONE=0
NOOP=0
SLEEP=0

function startup()
{
    insmod tmpm.ko
    sleep 1
    echo 11 > /sys/kernel/debug/tmpm/test_trigger
    sleep 1
}

function cleanup()
{
    echo 12 > /sys/kernel/debug/tmpm/test_trigger
    sleep 1
    rmmod tmpm
}

function migrate_once()
{
    if (( $PID == 0 )) ; then
	sleep 600 &
	PID=$!
	KILL_SLEEP=1
    fi
    migratepages $PID 0 1;
    if (( $SLEEP == 1 )) ; then sleep 1; fi
    migratepages $PID 1 2;
    if (( $SLEEP == 1 )) ; then sleep 1; fi
    migratepages $PID 2 0;
    if (( $SLEEP == 1 )) ; then sleep 1; fi
}

function migrate()
{
    sleep 600 &
    PID=$!
    KILL_SLEEP=1
    while [[ 1 ]]; do
	migrate_once
    done
}

function one_page()
{
    echo "10 > /sys/kernel/debug/tmpm/test_trigger"
    echo 10 > /sys/kernel/debug/tmpm/test_trigger
    sleep 3
    cleanup
}

function noop()
{
    echo "2 > /sys/kernel/debug/tmpm/test_trigger"
    echo 2 > /sys/kernel/debug/tmpm/test_trigger
    sleep 3
    cleanup
}

startup
ulimit -c unlimited
#
#   -o one iteration
#   -m migrate one page
#   -n no-op
#   -s sleep in between numa moves
#   -l load tmpm and set to offloading migration
#   -u unload

while (( $# > 0 ))
do
    case $(expr substr $1 1 1) in
        '-' )
              case $(expr substr $1 2 1) in
                  'o' ) ONCE=1;
			migrate_once;
			exit 0;;
                  'm' ) MIGRATE_ONE=1;
			one_page;
			cleanup;
			exit 0;;
		  'n' ) NOOP=1;
			noop;
			cleanup;
			exit 0;;
		  'l' ) exit 0;;
		  'u' ) cleanup;
			exit 0;;
		  's' ) SLEEP=1;;
                   *  ) echo "unsupported option $(expr substr $1 2 1) ignored";
                       exit 0;;
              esac
              ;;
    esac
    shift
done
#trap cleanup EXIT
#migrate

