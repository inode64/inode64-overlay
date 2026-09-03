# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="A user for openchamber"
ACCT_USER_ID=322
ACCT_USER_HOME=/var/lib/openchamber
ACCT_USER_GROUPS=( openchamber )

acct-user_add_deps
