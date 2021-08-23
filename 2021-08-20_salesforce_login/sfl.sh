#!/bin/sh
scope ()
(

    # ---------- VARIABLES -----------

    # use $1, $2 etc after ARGPARSE under ARGUMENTS

    script_path="$(dirname "$(readlink -e -- "$0")")"
    script_name="$(basename "$0")"
    num_args=1
    logfile_name=/dev/null
    unset quiet

    browser="chromium chromium-browser firefox-wayland firefox"

    # --------- HELP PAGE ------------

    help=$(cat <<EOF
$script_name - automatically open an sfdx authenticated org in browser

Usage:
	$script_name -h
	$script_name -q -l foo

Options:
	-h --help	Show this screen.
	-l --log	Write log to file $logfile_name.
	-q --quiet	Don't write to stdout.
	--		End of options.
EOF
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

    if [ "$#" -ne "$num_args" ]
    then
	printf "%b\n" "[ERROR] wrong number of arguments: should be $num_args\n$help"
	exit
    fi

    # ---------- ARGUMENTS -----------



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

    # ---------- MAIN ----------------

    main () {
	hello

	(
	    f=$(sfdx force:org:open -r -u "$1")
	    url=${f#*URL: }

	    log printf "%b\n" "$url"

	    for app in $browser
	    do
		if [ -n "$(which $app)" ]
		then
		    $app "$url"
		    break
		fi
	    done
	) >/dev/null 2>&1 &

    }
    log main $@
)
scope $@

# ---------- COMMENTS ------------
