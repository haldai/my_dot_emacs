#!/usr/bin/env bash

function run {
    if ! pgrep $1 ; then
        $@&
    fi
}

# Startups
run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
run undervolt.sh
run compton --config ~/.config/compton.conf
run ibus-daemon --xim -d
run nm-applet
run caffeine
run udiskie -ans
run blueman-applet
run libinput-gestures-setup start
run copyq
run thunderbird
run ss-qt5
sleep 1; /home/daiwz/.conky/myconky-start.sh
