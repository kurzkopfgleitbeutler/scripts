#!/bin/sh
sudo install -o root -g root -m 0755 scaf.sh /usr/local/bin/scaf
echo to uninstall, remove this file:
echo sudo rm /usr/local/bin/scaf
printf "%b" "sudo rm /usr/local/bin/scaf" | xclip -selection clipboard
