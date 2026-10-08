# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for the sci-ml/fastflowlm service; owns /var/lib/fastflowlm"
ACCT_USER_ID=975
ACCT_USER_HOME=/var/lib/fastflowlm
ACCT_USER_HOME_PERMS=2770
ACCT_USER_GROUPS=( fastflowlm )

acct-user_add_deps
