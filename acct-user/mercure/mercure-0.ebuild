# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="A user for mercure"
ACCT_USER_ID=600
ACCT_USER_HOME=/var/lib/mercure
ACCT_USER_GROUPS=( mercure )

acct-user_add_deps
