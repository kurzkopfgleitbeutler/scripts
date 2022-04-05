#!/bin/sh -e
scope ()
(
    for i in $(find . -mindepth 2 -maxdepth 2 -type f -name "install.sh")
    do
	cd "${i%/*}"
	./install.sh
	cd -
    done
)
scope $@
