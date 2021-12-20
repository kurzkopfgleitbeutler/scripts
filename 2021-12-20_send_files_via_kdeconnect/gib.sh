#!/bin/sh
scope ()
(

    # ---------- VARIABLES -----------

    # use $1, $2 etc after ARGPARSE under ARGUMENTS

    script_path="$(dirname "$(readlink -e -- "$0")")"
    script_name="$(basename "$0")"
    num_args=1
    num_args2=2
    logfile_name=/dev/null
    runtime_dependencies="getopt awk rofi"
    export SUDO_ASKPASS="$(which ssh-askpass)"
    unset quiet

    # --------- HELP PAGE ------------

    help=$(cat<<HELPAGE
$script_name - easily share files between kdeconnect-enabled devices

Usage:
	$script_name -h
	$script_name -q -l [target device] filename

Options:
	-h --help	Show this screen.
	-l --log	Write log to file $logfile_name.
	-q --quiet	Don't write to stdout.
	--		End of options.
HELPAGE
	)

    # -------- FLAG PARSING ----------

    parsed_args=$(getopt -a -n $script_name -o hlq --long help,log,quiet -- "$@")
    valid_args=$?
    if [ "$valid_args" != "0" ]
    then
	printf "%b\n" "$help"
	exit 2
    fi
    eval set -- "$parsed_args"
    while :
    do
	case "$1" in
	    -h | --help)  printf "%b\n" "$help" ; exit ;;
	    -l | --log)   logfile_name="log_${script_name%.*}.txt" ; shift ;;
	    -q | --quiet) quiet=1 ; shift ;;
	    --)           shift ; break ;;
	    *)            printf "%b\n" "Unexpected option: $1 - this should not happen.\n$help" ; exit 2 ;;
	esac
    done

    if [ "$#" -ne "$num_args" ] && [ "$#" -ne "$num_args2" ]
    then
	printf "%b\n" "[ERROR] wrong number of arguments: should be $num_args or $num_args2\n$help"
	exit 2
    fi

    # ---------- FUNCTIONS -----------

    hello () {
	# printf "%b\n" ""	# newline between log entries
	printf "%b\n" "[BEGIN] $(date -Iseconds) $script_path/$script_name"
    }
    log () {
	if [ -n "$quiet" ]
	then
	    "$@" >> $logfile_name
	else
	    "$@" | tee -a $logfile_name
	fi
    }
    check_for_app () {
	for dep in $@
	do
	    if [ -n "$(which $dep)" ]
	    then
		printf "%b\n" "found $dep"
	    else
		printf "%b\n" "[ERROR] $dep not found, aborting"
		exit
	    fi
	done
    }
    trysudo () {
	if [ -n "$(getent group sudo | grep -o $USER)" ]
	then
	    sudo -A "$@"
	else
	    printf "%b\n" "[WARN] $USER has no sudo rights: $@"
	fi
    }

    # ---------- MAIN ----------------

    main () {
    	hello
	check_for_app $runtime_dependencies

	if [ "$#" = 1 ]
	then
	    receiver=$( kdeconnect-cli --list-available --name-only | rofi -threads 0 -dmenu -i -auto-select -p "Send to which device?" )
	    if [ -n "$receiver" ]
	    then
		kdeconnect-cli --name "$receiver" --share "$(realpath $1)"
	    fi
	fi

	if [ "$#" = 2 ]
	then
	    available=$(kdeconnect-cli --list-available --name-only)
	    # https://stackoverflow.com/questions/229551/how-to-check-if-a-string-contains-a-substring-in-bash/20460402#20460402
	    if [ -z "${available##*$1*}" ] && [ -z "$1" -o -n "$available" ]
	    then
		kdeconnect-cli --name "$1" --share "$(realpath $2)"
	    fi
	fi


    }
    log main $@
)
scope $@

# ---------- COMMENTS ------------
