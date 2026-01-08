# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

ACCT_USER_ID=995
ACCT_USER_GROUPS=( alloy )
ACCT_USER_HOME=/var/lib/alloy
DESCRIPTION="Alloy Daemon"

acct-user_add_deps
