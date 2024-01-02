# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="A user for node-red"
ACCT_USER_ID=313
ACCT_USER_HOME=/var/lib/node-red
ACCT_USER_GROUPS=( node-red )

acct-user_add_deps
