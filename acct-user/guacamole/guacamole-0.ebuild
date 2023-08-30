# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="A user for Guacamole Guacamole server"
ACCT_USER_ID=311
ACCT_USER_HOME=/var/spool/guacamole
ACCT_USER_GROUPS=( guacamole )

acct-user_add_deps
