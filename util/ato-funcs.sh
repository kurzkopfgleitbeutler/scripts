#!/bin/sh

hello () {
    # printf "%b\n" ""	# newline between log entries
    if [ "$logfile_name" != "/dev/null" ]
    then
	printf "%b\n" "[BEGIN] $(date -Iseconds) $script_path/$script_name"
    fi
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
    if [ "$1" = "ERROR" ]
    then
	errout=1
	shift
    fi
    for dep in $@
    do
	if [ -n "$(which $dep)" ]
	then
	    if [ "$logfile_name" != "/dev/null" ]
	    then
		printf "%b\n" "found $dep"
	    fi
	else
	    if [ -n "$errout" ]
	    then
		if [ "$logfile_name" != "/dev/null" ]
		then
		    printf "%b\n" "[WARN] $dep not found, continuing"
		fi
	    else
		if [ "$logfile_name" != "/dev/null" ]
		then
		    printf "%b\n" "[ERROR] $dep not found, aborting"
		    unset errout
		fi
		exit
	    fi
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

counter () {
    # $XDG_STATE_HOME, see https://wiki.archlinux.org/title/XDG_Base_Directory
    prefix="$HOME/.local/state"
    var="c"
    if [ ! -d "$prefix" ]
    then
	mkdir -p "$prefix"
	if [ $? -ne 0 ]
	then
	    printf "%b\n" "[WARN] can't create $prefix"
	fi
    fi
    if [ ! -f "$prefix/$script_name" ]
    then
	printf "%b\n" "$var=1" > "$prefix/$script_name"
    fi
    if [ ! -w "$prefix/$script_name" ]
    then
	printf "%b\n" "[ERROR] not writable, check file/directory permissions of: $prefix/$script_name"
    fi
    countlinenumber=$(cat "$prefix/$script_name" | awk --posix '/^[[:space:]]*'$var'=[0-9]+[[:space:]]*$/ { print FNR; exit; }')
    if [ -z $countlinenumber ]
    then
	printf "%b\n" "[WARN] No line with count variable found"
    fi
    count=$(head -n $countlinenumber "$prefix/$script_name" | tail -n 1 | awk --posix -F'=' '{ print $2 }')
    newc="$var="$(($count + 1))
    before=$(head -n $(($countlinenumber - 1)) "$prefix/$script_name")
    after=$(tail -n +$(($countlinenumber + 1)) "$prefix/$script_name")
    printf %s "$before
$newc
$after" > "$prefix/$script_name"
    printf "%b\n" "[INFO] $(whoami) runs $script_name the ${count} time"
}
