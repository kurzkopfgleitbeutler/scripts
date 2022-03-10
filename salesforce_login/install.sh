#!/bin/sh
sudo install -o root -g root -m 0755 sfl.sh /usr/local/bin/sfl
echo to uninstall, remove this file:
echo sudo rm /usr/local/bin/sfl
printf "%b" "sudo rm /usr/local/bin/sfl" | xclip -selection clipboard
