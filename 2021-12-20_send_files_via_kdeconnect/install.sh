#!/bin/sh
sudo install -o root -g root -m 0755 gib.sh /usr/local/bin/gib
printf "%b\n" "to uninstall, remove this file:\nsudo rm /usr/local/bin/gib"
printf "%b" "sudo rm /usr/local/bin/gib" | xclip -selection clipboard
