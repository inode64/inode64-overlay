# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="A user for the nebula-mesh management server"
ACCT_USER_ID=989
ACCT_USER_GROUPS=( nebula-mgmt )
ACCT_USER_HOME=/var/lib/nebula-mgmt
ACCT_USER_HOME_OWNER=nebula-mgmt:nebula-mgmt
ACCT_USER_HOME_PERMS=0750

acct-user_add_deps
