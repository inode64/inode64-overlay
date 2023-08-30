# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="A user for go2rtc"
ACCT_USER_ID=991
ACCT_USER_GROUPS=( go2rtc video render )

acct-user_add_deps
