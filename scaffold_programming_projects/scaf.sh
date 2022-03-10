#!/bin/sh -e
# put into /usr/local/bin as 'scaf' (scaffold) for use from command line
# EITHER:
# sudo install -o root -g root -m 0755 $thispath/$SHORT.sh /usr/local/bin/$SHORT
# OR:
# chmod +x $thispath/scaf.sh
# sudo ln -vs $abspath/scaf.sh /usr/local/bin/scaf
scope () (

    # ---------- VARIABLES -----------

    script_path="$(dirname "$(readlink -e -- "$0")")"
    script_name="$(basename "$0")"
    num_args=2
    logfile_name=/dev/null
    runtime_dependencies="sudo ssh-askpass awk xclip getopt"
    export SUDO_ASKPASS="$(which ssh-askpass)"
    unset quiet
    unset distname

    # https://stackoverflow.com/a/39959192
    distname="$(awk -F'=' '/^ID=/ {print tolower($2)}' /etc/*-release)"
    targetdir="/usr/local/bin"

    # --------- HELP PAGE ------------

    help=$(cat <<EOF
$script_name - easily bootstrap a shell script project

Usage:
	$script_name -h
	$script_name -q -l short_alias full_name

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

    SHORT="$1"
    if [ -z "$quiet" ]
    then
	echo "SHORT is $SHORT"
    fi
    LONG="$2"
    SUBDIR="$(date -I)_$LONG"
    FH="$SHORT.sh"
    INSTALL="install.sh"

    # ------- TEMPLATE STRINGS -------

    # https://stackoverflow.com/questions/17983586/how-can-i-get-the-variable-value-inside-the-eof-tags/17983608#17983608
    template_script=$(cat <<\EOF
#!/bin/sh -e
scope ()
(

    # ---------- VARIABLES -----------
    . $HOME/scripts/util/ato-vars.sh

    # use $1, $2 etc after ARGPARSE under ARGUMENTS

    num_args_min=0
    num_args_max=256
    runtime_dependencies="dirname basename which cat getopt date awk"
    runtime_dependencies_optional="ssh-askpass sudo nohup"

    if [  "$distname" = "fedora" ]
    then :
    elif [ "$distname" = "ubuntu" ]
    then :
    fi

    # --------- HELP PAGE ------------

    help=$(cat<<HELPAGE
$script_name - TODO:tagline

Usage:
	$script_name -h
	$script_name -q -l TODO:foo

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
	printf "%b\\n" "$help"
	exit 2
    fi
    eval set -- "$parsed_args"
    while :
    do
	case "$1" in
	    -h | --help)  printf "%b\\n" "$help" ; exit ;;
	    -l | --log)   logfile_name="log_${script_name%.*}.txt" ; shift ;;
	    -q | --quiet) quiet=1 ; shift ;;
	    --)           shift ; break ;;
	    *)            printf "%b\\n" "Unexpected option: $1 - this should not happen.\\n$help" ; exit 2 ;;
	esac
    done
    . $HOME/scripts/util/ato-flags.sh

    # ---------- ARGUMENTS -----------



    # ------- TEMPLATE STRINGS -------

    # https://stackoverflow.com/questions/17983586/how-can-i-get-the-variable-value-inside-the-eof-tags/17983608#17983608
    foo=$(cat <<\TOKEN
bar
TOKEN
	)

    # ---------- FUNCTIONS -----------
    . $HOME/scripts/util/ato-funcs.sh



    # ---------- MAIN ----------------

    main () {
	. $HOME/scripts/util/ato-main.sh

	# . ./$SHORT-script.sh

    }
    log main $@
)
scope $@

# ---------- COMMENTS ------------

EOF
		   )

    template_install=$(cat <<EOF
#!/bin/sh
sudo install -o root -g root -m 0755 $FH $targetdir/$SHORT
printf "%b\\\n" "to uninstall, remove this file:\\\nsudo rm $targetdir/$SHORT"
printf "%b" "sudo rm $targetdir/$SHORT" | xclip -selection clipboard

EOF
		    )


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

	   mkdir "$SUBDIR"

	   printf "%b\n" "$template_script" > $SUBDIR/$FH
	   #" > $SUBDIR/wrap-$FH

	   printf "%b\n" "$template_install" > $SUBDIR/$INSTALL
	   chmod +x $SUBDIR/$INSTALL

	   if [ -w installemall.sh ]
	   then
	       printf "%b\n" "./$SUBDIR/$INSTALL" >> installemall.sh
	   fi

	   GOBACK=$(pwd)
	   cd $SUBDIR
	   git init
	   git add .
	   git commit -m 'initial commit'
	   cd $GOBACK

	   printf "%b\n" ""	# newline at end of output
       }
       log main $@
)
scope $@

# ---------- COMMENTS ------------
# https://stackoverflow.com/questions/5725296/difference-between-sh-and-bash
# http://pubs.opengroup.org/onlinepubs/9699919799/ see esp ‘Shell & Utilities’ > ‘Shell Command Language’ and ‘Utilities’
# http://mywiki.wooledge.org/Bashism
