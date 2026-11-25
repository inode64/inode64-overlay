#!/bin/bash

# The Sciter client captures the keyboard with an X11 grab (rdev), which only
# receives keys while an X11 window has the focus. GTK3 opens the window
# natively on Wayland, so keep it on Xwayland as upstream's AppImage does.
export GDK_BACKEND=x11

cd /usr/share/rustdesk/ || exit
exec ./rustdesk "$@"
