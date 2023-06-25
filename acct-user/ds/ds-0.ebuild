# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="A user for OnlyOffice document server"
ACCT_USER_ID=551
ACCT_USER_HOME=/usr/share/onlyoffice/documentserver
ACCT_USER_GROUPS=( ds )

acct-user_add_deps
