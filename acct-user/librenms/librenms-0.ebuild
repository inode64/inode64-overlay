# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="A user for Librenms"
ACCT_USER_ID=312
ACCT_USER_HOME=/opt/librenms
ACCT_USER_GROUPS=( librenms )

acct-user_add_deps
