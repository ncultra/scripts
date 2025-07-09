#!/usr/bin/env bash

ONCE=0
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

function one_page()
{
    echo "10 > /sys/kernel/debug/tmpm/test_trigger"
    echo 10 > /sys/kernel/debug/tmpm/test_trigger
    sleep 1
    cleanup
}

function loop_page()
{
    echo "11 > /sys/kernel/debug/tmpm/test_trigger"
    echo 11 > /sys/kernel/debug/tmpm/test_trigger
    sleep 1
    cleanup
}

function noop()
{
    echo "2 > /sys/kernel/debug/tmpm/test_trigger"
    echo 2 > /sys/kernel/debug/tmpm/test_trigger
    sleep 3
    cleanup
}

function capabilities()
{
    echo "4 > /sys/kernel/debug/tmpm/test_trigger"
    echo 4 > /sys/kernel/debug/tmpm/test_trigger
    sleep 3
    cleanup
}

function unsupported()
{
    echo "44 > /sys/kernel/debug/tmpm/test_trigger"
    echo 44 > /sys/kernel/debug/tmpm/test_trigger
    sleep 3
    cleanup
}
#ulimit -c unlimited

#   -l loop migrating one page
#   -m migrate one page
#   -n no-op
#   -c get capabilities

trap cleanup EXIT
while (( $# > 0 ))
do
    case $(expr substr $1 1 1) in
        '-' )
              case $(expr substr $1 2 1) in
		  'm' ) startup;
			loop_page;
			exit 0;;
		  'n' ) NOOP=1;
			startup;
			noop;
			exit 0;;
		  'c' ) startup;
			capabilities;
			exit 0 ;;
		  'M' ) startup;
			loop_page;
			exit 0;;
                   *  ) echo "unsupported option $(expr substr $1 2 1) ignored";
                       exit 0;;
              esac
              ;;
    esac
    shift
done


