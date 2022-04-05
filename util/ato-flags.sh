#!/bin/sh
if [ -n "$num_args_min" ] && [ -n "$num_args_max" ]
then
    if [ "$#" -lt "$num_args_min" ] || [ "$#" -gt "$num_args_max" ]
    then
	printf "%b\n" "[ERROR] wrong number of arguments: should be between $num_args_min and $num_args_max\n$help"
	exit 2
    fi
fi
