# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for sci-ml/lemonade"
ACCT_USER_ID=974
ACCT_USER_HOME=/var/lib/lemonade
ACCT_USER_HOME_PERMS=0750
ACCT_USER_GROUPS=( lemonade fastflowlm )

acct-user_add_deps
