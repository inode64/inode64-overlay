# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for the app-misc/bifrost-bin service; owns /var/lib/bifrost"
ACCT_USER_ID=976
ACCT_USER_HOME=/var/lib/bifrost
ACCT_USER_HOME_PERMS=0750
ACCT_USER_GROUPS=( bifrost )

acct-user_add_deps
