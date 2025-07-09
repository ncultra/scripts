#! /usr/bin/env bash

THIS_PID=$$
MAX_STACK_DEPTH=100
TRACING_DIR="/sys/kernel/debug/tracing"

# mark_trace $1 string
mark_trace()
{
    echo "$1" > "$TRACING_DIR"/trace_marker
}

clear_trace()
{
    echo "" > "$TRACING_DIR"/trace;
}

stop_trace()
{
    echo 0 > "$TRACING_DIR"/tracing_on
}

# stack_trace $1 symbol $2 pid
stack_trace()
{
    pushd "$TRACING_DIR" &>/dev/null;
    echo 0 > tracing_on
    echo "function_graph" > current_tracer
#    echo "$MAX_STACK_DEPTH" > max_graph_depth
    echo "$1" > set_graph_function
    echo "$2" > set_ftrace_pid
    echo 1 > tracing_on
    popd &>/dev/null
}

# full_stack_trace $1 symbol $2 pid
full_stack_trace()
{
    pushd "$TRACING_DIR" &>/dev/null;

    echo 0 > tracing_on
    echo "function" > current_tracer
    echo 1 > options/func_stack_trace
    echo "$1" > set_ftrace_filter
    echo "$2" > set_ftrace_pid
    echo 1 > tracing_on
    popd &>/dev/null
}

<<MULTILINE_COMMENT
# stack.sh --pid <pid> --symbol <symbol to start trace>
TEMP=$(getopt -o'p:s:ch' -l 'pid:,symbol:,help,clear,stop' -n'$0' -- "$@")
if [ $? -ne 0 ]; then
    echo "Exiting" >&2
    exit 1
fi

eval set -- "$TEMP"
unset TEMP

while (( $# > 0 )); do
    case "$1" in
	'--pid') THIS_PID=$2; shift 2; continue;;
	'--symbol') SYMBOL=$2; shift 2; continue;;
	'--clear') clear_trace; shift; continue;;
	'--stop' ) stop_trace; exit 0;;
	'--help' ) echo "--pid <process ID> the process to trace";
		   echo "--symbol <name> the function that starts the stack trace";
		   echo "--clear clear the trace file"
		   echo "--stop stop tracing"
		   exit 0;;
	'--') shift; break;;
	*) echo 'Internal error!' >&2
	    exit 1;;
    esac
done


stack_trace $SYMBOL $THIS_PID
MULTILINE_COMMENT
