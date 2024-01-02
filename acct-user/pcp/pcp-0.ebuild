# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

ACCT_USER_ID=973
ACCT_USER_GROUPS=( pcp )
ACCT_USER_HOME=/var/lib/pcp
DESCRIPTION="Performance Co-Pilot"

acct-user_add_deps
