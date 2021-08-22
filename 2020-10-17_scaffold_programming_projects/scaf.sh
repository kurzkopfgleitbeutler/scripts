#!/bin/sh
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
    usage="$script_name [-q] [-l] SHORTALIAS FULLNAME"
    tagline="easily bootstrap a shell script project"
    logfile_name=/dev/null
    runtime_dependencies="sudo ssh-askpass awk xclip"
    export SUDO_ASKPASS="$(which ssh-askpass)"
    unset quiet
    unset distname

    # https://stackoverflow.com/a/39959192
    distname="$(awk -F'=' '/^ID=/ {print tolower($2)}' /etc/*-release)"
    targetdir="/usr/local/bin"

    # -------- FLAG PARSING ----------

    while getopts 'lq' c
    do
	case $c in
	    l) logfile_name="log_${script_name%.*}.txt"; shift ;;
	    q) quiet=1; shift ;;
	    --) shift; break ;;
	    *) printf "%b\n" "[ERROR] unsupported flag: $1\n$usage"; exit ;;
	esac
    done
    if [ "$#" -ne "$num_args" ]
    then
	echo "[ERROR] wrong number of arguments: should be $num_args\n$usage"
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
#!/bin/sh
scope ()
(

    # ---------- VARIABLES -----------

    # use $1, $2 etc after ARGPARSE under ARGUMENTS

    script_path="$(dirname "$(readlink -e -- "$0")")"
    script_name="$(basename "$0")"
    num_args=1
    usage="$script_name [-q] [-l] ARG1"
    tagline"tagline of script"
    logfile_name=/dev/null
    runtime_dependencies="awk"
    export SUDO_ASKPASS="$(which ssh-askpass)"
    unset quiet
    unset distname

    distname="$(awk -F'=' '/^ID=/ {print tolower($2)}' /etc/*-release)"

    if [  "$distname" == "fedora" ]
    then
    elif [ "$distname" == "ubuntu" ]
    then
    fi

    # -------- FLAG PARSING ----------

    while getopts 'lq' c
    do
	case $c in
	    l) logfile_name="log_${script_name%.*}.txt"; shift ;;
	    q) quiet=1; shift ;;
	    --) shift; break ;;
	    *) printf "%b\\n" "[ERROR] unsupported flag: $1\\n$usage"; exit ;;
	esac
    done
    if [ "$#" -ne "$num_args" ]
    then
	echo "[ERROR] wrong number of arguments: should be $num_args\\n$usage"
	exit
    fi

    # ---------- ARGUMENTS -----------



    # ------- TEMPLATE STRINGS -------

    # https://stackoverflow.com/questions/17983586/how-can-i-get-the-variable-value-inside-the-eof-tags/17983608#17983608
    foo=$(cat <<\TOKEN
bar
TOKEN
	)

    # ---------- FUNCTIONS -----------

    hello () {
	printf "%b\\n" ""	# newline between log entries
	printf "%b\\n" "[BEGIN] $(date -Iseconds)\\n$script_path/$script_name\\n$usage\\n$tagline"
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
		printf "%b\\n" "found $dep"
	    else
		printf "%b\\n" "[ERROR] $dep not found, aborting"
		exit
	    fi
	done
    }
    trysudo () {
	if [ -n "$(getent group sudo | grep -o $USER)" ]
	then
	    sudo -A "$@"
	else
	    printf "%b\\n" "[WARN] $USER has no sudo rights: $@"
	fi
    }

    # ---------- MAIN ----------------

    main () {
    	hello
	check_for_app $runtime_dependencies

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
	printf "%b\n" ""	# newline between log entries
	printf "%b\n" "[BEGIN] $(date -Iseconds)\n$script_path/$script_name\n$usage"
	printf "%b\n" "$tagline"
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
