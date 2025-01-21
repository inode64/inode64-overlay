# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="A user for zigbee2mqtt"
ACCT_USER_ID=313
ACCT_USER_HOME=/var/lib/zigbee2mqtt
ACCT_USER_GROUPS=( zigbee2mqtt dialout )

acct-user_add_deps
