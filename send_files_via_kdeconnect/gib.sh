#!/bin/sh
scope ()
(

    # ---------- VARIABLES -----------
    . $HOME/scripts/util/ato-vars.sh

    # use $1, $2 etc after ARGPARSE under ARGUMENTS

    num_args_min=1
    num_args_max=2
    runtime_dependencies="getopt awk rofi"
    export SUDO_ASKPASS="$(which ssh-askpass)"

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
    . $HOME/scripts/util/ato-flags.sh

    # ---------- FUNCTIONS -----------
    . $HOME/scripts/util/ato-funcs.sh

    # ---------- MAIN ----------------

    main () {
	. $HOME/scripts/util/ato-main.sh

	# sender -> message -> receiver
	if [ "$#" = 2 ]
	then
	    receiver="$1"
	    shift
	else
	    receiver=$( kdeconnect-cli --list-available --name-only | rofi -threads 0 -dmenu -i -auto-select -p "Send to which device?" )
	fi
	message="$1"

	# https://stackoverflow.com/questions/229551/how-to-check-if-a-string-contains-a-substring-in-bash/20460402#20460402
	# if [ -z "${available##*$receiver*}" ] && [ -z "$receiver" -o -n "$available" ]
	available=$(kdeconnect-cli --list-available --name-only)
	if [ -z "${available##*$receiver*}" ]
	then
	    if [ -d "$message" ]
	    then
		printf "%b\n" "Sending directories is not yet fully supported. Proceed with care!\nTODO:\n\tmultilevel dirs\n\tremoving zip after sharing\n\tzip name collisions"
		exit 1

		zipfile="$(printf "%b" "$message" | awk -F'/' '{ print $(NF) }')"
		if [ -z "$zipfile" ]
		then
		    zipfile="$(printf "%b" "$message" | awk -F'/' '{ print $(NF-1) }')"
		fi
		zipfile="${zipfile}.zip"

		zip -r "$zipfile" "$message"
		kdeconnect-cli --name "$receiver" --share "$(realpath $zipfile)"
		# BUG: if I rm the zipfile after this, sending fails, even if I "&& wait && rm" on it
	    else
		kdeconnect-cli --name "$receiver" --share "$(realpath $message)"
	    fi
	fi

    }
    log main $@
)
scope $@

# ---------- COMMENTS ------------
